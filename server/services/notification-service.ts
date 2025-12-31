import { storage } from '../storage';
import { sendEmail } from './email';
import whatsAppService from './channels/whatsapp';
import { User } from '@shared/schema';

type NotificationType = 'task_assigned' | 'task_completed' | 'lead_assigned' | 'system_alert' | 'conversation_assigned';

interface NotificationPayload {
    userId: number;
    type: NotificationType;
    title: string;
    message: string;
    data?: any;
    channel?: 'auto' | 'whatsapp' | 'email' | 'system';
}

class NotificationService {
    private static instance: NotificationService;

    private constructor() { }

    static getInstance(): NotificationService {
        if (!NotificationService.instance) {
            NotificationService.instance = new NotificationService();
        }
        return NotificationService.instance;
    }

    /**
     * Send a notification to a specific user based on their preferences
     */
    async notifyUser(payload: NotificationPayload): Promise<{ success: boolean; channels: string[] }> {
        const { userId, type, title, message, channel = 'auto' } = payload;
        const channelsSent: string[] = [];

        try {
            const user = await storage.getUser(userId);
            if (!user) {
                console.warn(`[NotificationService] User ${userId} not found.`);
                return { success: false, channels: [] };
            }

            const preferences = user.notificationPreferences as Record<string, boolean>;

            // Determine effective permissions based on channel selection
            let emailEnabled = preferences?.email !== false; // Default true
            let whatsappEnabled = preferences?.whatsapp === true; // Default false

            // Override permissions if a specific channel is forced
            if (channel === 'email') {
                emailEnabled = true;
                whatsappEnabled = false;
            } else if (channel === 'whatsapp') {
                whatsappEnabled = true;
                emailEnabled = false;
            } else if (channel === 'system') {
                // System only
                emailEnabled = false;
                whatsappEnabled = false;
            }

            // 1. Send Email Notification
            if (emailEnabled && user.email) {
                try {
                    const emailSubject = `[System Notification] ${title}`;
                    const success = await sendEmail(user.email, emailSubject, message);
                    if (success) channelsSent.push('email');
                } catch (error) {
                    console.error(`[NotificationService] Failed to send email to user ${userId}:`, error);
                }
            }

            // 2. Send WhatsApp Notification
            if (whatsappEnabled && user.mobilePhone) {
                try {
                    const sent = await this.sendWhatsAppNotification(user, message);
                    if (sent) channelsSent.push('whatsapp');
                } catch (error) {
                    // Only log error if strictly forced, otherwise just warn
                    if (channel === 'whatsapp') {
                        console.error(`[NotificationService] Failed to send WhatsApp to user ${userId}:`, error);
                    }
                }
            }

            return { success: channelsSent.length > 0, channels: channelsSent };

        } catch (error) {
            console.error('[NotificationService] Error processing notification:', error);
            return { success: false, channels: [] };
        }
    }

    private async sendWhatsAppNotification(user: User, message: string): Promise<boolean> {
        if (!user.mobilePhone || !user.companyId) return false;

        try {
            // Find a suitable WhatsApp connection for the company to send FROM
            // We prioritize the most stable/active connection available
            const channels = await storage.getChannelConnections(user.companyId);
            const whatsappChannel = channels.find(c =>
                (c.status === 'connected' || c.status === 'active') &&
                (c.channelType === 'whatsapp' || c.channelType === 'whatsapp_unofficial' || c.channelType === 'whatsapp_official')
            );

            if (!whatsappChannel) {
                console.warn(`[NotificationService] No active WhatsApp channel found for company ${user.companyId} to send notification.`);
                return false;
            }

            await whatsAppService.sendMessage(
                whatsappChannel.id,
                whatsappChannel.userId,
                user.mobilePhone,
                message,
                true // isFromBot
            );

            return true;

        } catch (error) {
            console.error(`[NotificationService] WhatsApp send error for user ${user.id}:`, error);
            return false;
        }
    }
}

export const notificationService = NotificationService.getInstance();
