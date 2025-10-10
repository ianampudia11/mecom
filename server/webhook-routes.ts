import express, { type Express } from "express";
import { storage } from "./storage";
import whatsAppOfficialService from "./services/channels/whatsapp-official";
import whatsApp360DialogPartnerService from "./services/channels/whatsapp-360dialog-partner";
import {
  create360DialogWebhookSecurity,
  createWhatsAppWebhookSecurity,
  verifyWhatsAppWebhookSignature,
  logWebhookSecurityEvent
} from "./middleware/webhook-security";

/**
 * Register webhook endpoints before any JSON middleware to avoid body parsing conflicts
 * This ensures webhooks receive raw bodies for proper signature verification
 */
export function registerWebhookRoutes(app: Express): void {
  

  app.get('/api/webhooks/whatsapp', async (req, res) => {
    const mode = req.query['hub.mode'];
    const token = req.query['hub.verify_token'];
    const challenge = req.query['hub.challenge'];
    

    console.log('WhatsApp webhook verification attempt:', {
      mode,
      token: token ? `${token.toString().substring(0, 8)}...` : 'undefined',
      challenge: challenge ? `${challenge.toString().substring(0, 8)}...` : 'undefined',
      userAgent: req.get('User-Agent'),
      ip: req.ip
    });

    if (mode !== 'subscribe') {

      return res.status(403).send('Forbidden');
    }

    try {

      const whatsappConnections = await storage.getChannelConnectionsByType('whatsapp_official');
      
      let matchingConnection = null;
      for (const connection of whatsappConnections) {
        const connectionData = connection.connectionData as any;
        if (connectionData?.verifyToken === token) {
          matchingConnection = connection;
          break;
        }
      }


      const globalToken = process.env.WHATSAPP_WEBHOOK_VERIFY_TOKEN || 'default_verify_token';
      const isGlobalMatch = token === globalToken;

      if (matchingConnection || isGlobalMatch) {
                res.status(200).send(challenge);
      } else {
        console.log('❌ WhatsApp webhook verification failed:', {
          receivedToken: token,
          globalToken: globalToken,
          checkedConnections: whatsappConnections.length,
          availableTokens: whatsappConnections.map(conn => {
            const data = conn.connectionData as any;
            return data?.verifyToken ? `${data.verifyToken.substring(0, 8)}...` : 'none';
          })
        });
        res.status(403).send('Forbidden');
      }
    } catch (error) {
      console.error('Error during WhatsApp webhook verification:', error);
      res.status(500).send('Internal Server Error');
    }
  });


  app.post('/api/webhooks/whatsapp',
    createWhatsAppWebhookSecurity(),
    express.raw({ type: 'application/json' }),
    async (req, res) => {
    try {
      const signature = req.headers['x-hub-signature-256'] as string;
      const body = req.body;

      console.log('WhatsApp webhook received:', {
        hasSignature: !!signature,
        bodyType: typeof body,
        bodyConstructor: body?.constructor?.name,
        isBuffer: Buffer.isBuffer(body),
        bodyLength: body?.length || 'unknown',
        contentType: req.get('content-type'),
        headers: {
          'x-hub-signature-256': signature ? 'present' : 'missing',
          'user-agent': req.get('user-agent')
        }
      });


      const payload = JSON.parse(body.toString());

      

      let phoneNumberId: string | null = null;
      if (payload.entry && payload.entry.length > 0) {
        const entry = payload.entry[0];
        if (entry.changes && entry.changes.length > 0) {
          const change = entry.changes[0];
          if (change.value && change.value.metadata) {
            phoneNumberId = change.value.metadata.phone_number_id;
          }
        }
      }


      let targetConnection = null;
      let appSecret = null;
      let secretSource = 'none';

      if (phoneNumberId) {

        const whatsappConnections = await storage.getChannelConnectionsByType('whatsapp_official');
        targetConnection = whatsappConnections.find(conn => {
          const data = conn.connectionData as any;
          return data?.phoneNumberId === phoneNumberId || data?.businessAccountId === phoneNumberId;
        });

        if (targetConnection) {
          const connectionData = targetConnection.connectionData as any;
          appSecret = connectionData?.appSecret;
          secretSource = `connection_${targetConnection.id}_company_${targetConnection.companyId}`;

                  } else {
          console.warn('No connection found for phone number ID:', phoneNumberId);
        }
      }


      if (!appSecret) {
        appSecret = process.env.FACEBOOK_APP_SECRET;
        secretSource = 'global_env';
      }

      

      if (appSecret && signature) {

        if (!Buffer.isBuffer(body)) {
          console.error('Expected Buffer but got:', typeof body, body?.constructor?.name);
          return res.status(400).send('Invalid request body - expected raw body');
        }

        const isValid = whatsAppOfficialService.verifyWebhookSignature(signature, body, appSecret);
        if (!isValid) {
                    return res.status(403).send('Forbidden');
        }
              } else {
              }


      await whatsAppOfficialService.processWebhook(payload, targetConnection?.companyId || undefined);

      res.status(200).send('OK');
    } catch (error) {
      console.error('Error processing WhatsApp webhook:', error);
      res.status(500).send('Internal Server Error');
    }
  });


  app.post('/api/webhooks/360dialog-partner',
    create360DialogWebhookSecurity(),
    express.json(),
    async (req, res) => {
      try {
        const payload = req.body;

        logWebhookSecurityEvent('signature_verified', {
          ip: req.ip,
          userAgent: req.get('User-Agent'),
          endpoint: '360dialog-partner'
        });

        if (!payload.id || !payload.event) {
          console.warn('Invalid 360Dialog Partner webhook payload:', payload);
          return res.status(400).json({ error: 'Invalid payload' });
        }

        
        await whatsApp360DialogPartnerService.processPartnerWebhook(payload);
        res.status(200).send('OK');
      } catch (error) {
        console.error('Error processing 360Dialog Partner webhook:', error);
        res.status(500).json({ error: 'Internal server error' });
      }
    }
  );


  app.post('/api/webhooks/360dialog-messaging',
    create360DialogWebhookSecurity(),
    express.json(),
    async (req, res) => {
      try {
        const payload = req.body;

        logWebhookSecurityEvent('signature_verified', {
          ip: req.ip,
          userAgent: req.get('User-Agent'),
          endpoint: '360dialog-messaging'
        });

        if (!payload.object || !payload.entry) {
          console.warn('Invalid 360Dialog Messaging webhook payload:', payload);
          return res.status(400).json({ error: 'Invalid payload' });
        }

        
        await whatsApp360DialogPartnerService.processMessagingWebhook(payload);
        res.status(200).send('OK');
      } catch (error) {
        console.error('Error processing 360Dialog Messaging webhook:', error);
        res.status(500).json({ error: 'Internal server error' });
      }
    }
  );


  app.get('/api/webhooks/test', (req, res) => {
    res.json({
      message: 'Webhook routes are working',
      timestamp: new Date().toISOString(),
      registeredBefore: 'JSON middleware'
    });
  });


}
