import { useEffect } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import useSocket from '@/hooks/useSocket';

export function WebSocketListener() {
    const queryClient = useQueryClient();
    const { lastMessage } = useSocket('/ws');

    useEffect(() => {
        if (!lastMessage) return;

        if (lastMessage.type === 'contactUpdated') {
            console.log('WS: contactUpdated received', lastMessage.data);
            queryClient.invalidateQueries({ queryKey: ['/api/contacts'] });
            queryClient.invalidateQueries({ queryKey: ['/api/conversations'] });
            if (lastMessage.data?.id) {
                queryClient.invalidateQueries({ queryKey: [`/api/contacts/${lastMessage.data.id}`] });
            }
        }

        if (lastMessage.type === 'dealUpdated') {
            console.log('WS: dealUpdated received', lastMessage.data);
            queryClient.invalidateQueries({ queryKey: ['/api/deals'] });
            // Also invalidate contacts because deal update might affect contact (sync)
            queryClient.invalidateQueries({ queryKey: ['/api/contacts'] });
        }

        // Handle other existing events if needed
    }, [lastMessage, queryClient]);

    return null;
}
