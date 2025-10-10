import express, { type Request, Response, NextFunction } from "express";
import { registerRoutes } from "./routes";
import { migrationSystem } from "./migration-system";
import path from "path";
import { logger } from "./utils/logger";
import { runtimeProtection } from "./utils/runtime-protection";
import { setupSecurityMiddleware, setupSecurityReporting } from "./middleware/security";
import { serveStatic } from "./static-server";
import { ensureUploadDirectories } from "./utils/file-system";
import dotenv from "dotenv";
import { registerWebhookRoutes } from "./webhook-routes";


dotenv.config();


if (process.env.NODE_ENV === 'production') {
  if (!runtimeProtection.isSecureEnvironment()) {
    console.error('🚨 Insecure environment detected');
    process.exit(1);
  }
}

const app = express();


if (process.env.NODE_ENV === 'production') {
  setupSecurityMiddleware(app);
}

registerWebhookRoutes(app);

app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: false, limit: '50mb' }));

app.use((req, res, next) => {
  const start = Date.now();
  const path = req.path;
  let capturedJsonResponse: Record<string, any> | undefined = undefined;

  const originalResJson = res.json;
  res.json = function (bodyJson, ...args) {
    capturedJsonResponse = bodyJson;
    return originalResJson.apply(res, [bodyJson, ...args]);
  };

  res.on("finish", () => {
    const duration = Date.now() - start;
    if (path.startsWith("/api")) {
      logger.info(
        "api",
        `${req.method} ${path} ${res.statusCode} in ${duration}ms`,
        capturedJsonResponse,
      );
    }
  });

  next();
});

(async () => {

  await ensureUploadDirectories();

  const server = await registerRoutes(app);


  setupSecurityReporting(app);

  app.use((err: any, _req: Request, res: Response, _next: NextFunction) => {
    const status = err.status || err.statusCode || 500;
    const message = err.message || "Internal Server Error";

    res.status(status).json({ message });
    throw err;
  });


  if (process.env.NODE_ENV === 'production') {
    serveStatic(app);
  }


  const basePort = parseInt(process.env.PORT || "9000", 10);
  const port = process.env.NODE_ENV === 'development' ? basePort + 100 : basePort;
  server.listen({
    port,
    host: "0.0.0.0",
    reusePort: true,
  }, () => {
    logger.info('server', `Server running on port ${port}`);

    setTimeout(async () => {
      try {
        logger.info('migration', 'Running database migrations...');
        await migrationSystem.runPendingMigrations();
        logger.info('migration', 'Database migrations completed successfully');

        logger.info('whatsapp', 'Starting WhatsApp auto-reconnection...');
        const { autoReconnectWhatsAppSessions, checkAndRecoverConnections } = await import('./services/channels/whatsapp');
        await autoReconnectWhatsAppSessions();

        setInterval(async () => {
          try {
            await checkAndRecoverConnections();
          } catch (error) {
            logger.error('whatsapp', 'Error during periodic connection check', error);
          }
        }, 5 * 60 * 1000);

        logger.info('email', 'Auto-reconnecting email connections...');
        const { autoReconnectEmailConnections, startAllEmailPolling } = await import('./services/channels/email');
        await autoReconnectEmailConnections();

        logger.info('email', 'Starting database-driven email polling...');
        try {
          await startAllEmailPolling();
          logger.info('email', '✅ Email polling startup completed successfully');
        } catch (error) {
          logger.error('email', '❌ Email polling startup failed:', error);
        }

        logger.info('messenger', 'Initializing Messenger health monitoring...');
        try {
          const { initializeHealthMonitoring } = await import('./services/channels/messenger');
          await initializeHealthMonitoring();
          logger.info('messenger', '✅ Messenger health monitoring initialized successfully');
        } catch (error) {
          logger.error('messenger', '❌ Messenger health monitoring initialization failed:', error);
        }

        logger.info('messenger', 'Ensuring Messenger channels are active...');
        try {
          const { storage } = await import('./storage');
          const updatedCount = await storage.ensureMessengerChannelsActive();
          logger.info('messenger', `✅ Ensured ${updatedCount} Messenger channels are active`);
        } catch (error) {
          logger.error('messenger', '❌ Failed to ensure Messenger channels are active:', error);
        }


        const retryEmailPolling = async (attempt: number = 1, maxAttempts: number = 3) => {
          try {
            logger.info('email', `🔄 Email polling retry attempt ${attempt}/${maxAttempts}...`);
            await startAllEmailPolling();
            logger.info('email', `✅ Email polling retry ${attempt} completed successfully`);
          } catch (error) {
            logger.error('email', `❌ Email polling retry ${attempt} failed:`, error);
            if (attempt < maxAttempts) {
              setTimeout(() => retryEmailPolling(attempt + 1, maxAttempts), 15000 * attempt); // Exponential backoff
            }
          }
        };


        setTimeout(() => retryEmailPolling(1, 3), 10000);


        setTimeout(() => retryEmailPolling(2, 3), 30000);


        setTimeout(() => retryEmailPolling(3, 3), 60000);


        setInterval(async () => {
          try {
            const emailService = await import('./services/channels/email');
            const connectionsStatus = await emailService.getEmailConnectionsStatus();
            const activePolling = connectionsStatus.filter(c => c.pollingActive).length;
            logger.debug('email', `Email health check: ${connectionsStatus.length} total connections, ${activePolling} actively polling`);
          } catch (error) {
            logger.error('email', 'Error during periodic email health check', error);
          }
        }, 10 * 60 * 1000); // Check every 10 minutes


        logger.info('backup', 'Initializing backup scheduler...');
        const { inboxBackupSchedulerService } = await import('./services/inbox-backup-scheduler');
        await inboxBackupSchedulerService.initializeScheduler();

        logger.info('campaigns', 'Starting campaign queue processor...');
        const { CampaignQueueService } = await import('./services/campaignQueueService');
        const campaignQueueService = new CampaignQueueService();
        campaignQueueService.startQueueProcessor();

        logger.info('flow-analytics', 'Initializing Flow Analytics Service...');
        const { FlowAnalyticsService } = await import('./services/flow-analytics-service');
        const { storage } = await import('./storage');
        FlowAnalyticsService.getInstance(storage);

        logger.info('follow-ups', 'Starting Follow-up Scheduler...');
        const FollowUpScheduler = (await import('./services/follow-up-scheduler')).default;
        const followUpScheduler = FollowUpScheduler.getInstance();
        followUpScheduler.start();

        logger.info('follow-up-cleanup', 'Starting Follow-up Cleanup Service...');
        const FollowUpCleanupService = (await import('./services/follow-up-cleanup')).default;
        const followUpCleanupService = FollowUpCleanupService.getInstance();
        followUpCleanupService.start();

        logger.info('trials', 'Trial management available via API endpoints');

        logger.info('subscription', 'Starting Enhanced Subscription Scheduler...');
        const { subscriptionScheduler } = await import('./services/subscription-scheduler');
        subscriptionScheduler.start();

      } catch (error) {
        logger.error('startup', 'Error during service initialization', error);
      }
    }, 1000);
  });
})();
