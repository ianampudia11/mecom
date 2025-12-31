import { useQuery } from '@tanstack/react-query';
import { apiRequest } from '@/lib/queryClient';
import { Button } from "@/components/ui/button";
import { History as HistoryIcon } from "lucide-react";
import { Deal } from '@shared/schema';

interface DealAppointmentIndicatorProps {
    deal: Deal;
    onClick: (deal: Deal) => void;
}

export function DealAppointmentIndicator({ deal, onClick }: DealAppointmentIndicatorProps) {
    // We'll default to Google provider for the count for now, 
    // or we could iterate/check preferences. 
    // Assuming Google is primary. To be robust, we'd check all connect providers but let's start with Google.
    // Ideally this count should come from backend with the deal, but for now we fetch.

    const { data: events = [] } = useQuery({
        queryKey: [`/api/google/calendar/events`, 'indicator', deal.id],
        queryFn: async () => {
            const start = new Date();
            start.setMonth(start.getMonth() - 6); // Look back 6 months

            const end = new Date();
            end.setFullYear(end.getFullYear() + 1); // Look ahead 1 year

            const defaultCalendarId = localStorage.getItem('defaultGoogleCalendarId') || 'primary';
            const query = new URLSearchParams({
                timeMin: start.toISOString(),
                timeMax: end.toISOString(),
                maxResults: '100',
                singleEvents: 'true',
                orderBy: 'startTime',
                calendarId: defaultCalendarId
            });

            try {
                const res = await apiRequest("GET", `/api/google/calendar/events?${query.toString()}`);
                if (!res.ok) return [];
                const data = await res.json();
                return data.items || [];
            } catch (e) {
                return [];
            }
        },
        staleTime: 60000,
    });

    const relevantEvents = (Array.isArray(events) ? events : []).filter((event: any) => {
        const dealData = deal as any;
        const contactEmail = dealData.contact?.email?.toLowerCase();
        const contactName = dealData.contact?.name?.toLowerCase();

        if (!contactEmail && !contactName) return false;

        const attendees = event.attendees || [];
        const hasAttendee = attendees.some((a: any) => a.email?.toLowerCase() === contactEmail || a === contactEmail);

        if (!contactEmail && contactName) {
            const nameParts = contactName.split(' ').filter((part: string) => part.length > 2);
            const summaryLower = event.summary?.toLowerCase() || '';
            const descriptionLower = event.description?.toLowerCase() || '';

            // Match if any significant name part is found in title or description
            const nameMatch = nameParts.some((part: string) =>
                summaryLower.includes(part) || descriptionLower.includes(part)
            );

            return nameMatch;
        }
        return hasAttendee;
    });

    const now = new Date();
    // Consider an event pending/future if it hasn't ENDED yet
    const futureEvents = relevantEvents.filter((e: any) => {
        const endTime = new Date(e.end.dateTime || e.end.date || e.start.dateTime || e.start.date);
        return endTime > now;
    });
    const pastEvents = relevantEvents.filter((e: any) => {
        const endTime = new Date(e.end.dateTime || e.end.date || e.start.dateTime || e.start.date);
        return endTime <= now;
    });

    const pendingCount = futureEvents.length;
    const hasPastHistory = pastEvents.length > 0;

    const getIconColor = () => {
        if (pendingCount > 0) return "text-gray-500 hover:text-blue-600"; // Default behavior for pending
        if (hasPastHistory) return "text-orange-500 hover:text-orange-600"; // Orange for past history
        return "text-gray-300 hover:text-gray-500"; // Default empty (lighter gray)
    };

    return (
        <Button
            variant="ghost"
            size="icon"
            className={`h-8 w-8 relative ${getIconColor()} hover:bg-gray-50`}
            onClick={(e) => {
                e.stopPropagation();
                onClick(deal);
            }}
            title={hasPastHistory ? "Ver Historial (Citas Pasadas)" : "Ver Historial de Citas"}
        >
            <HistoryIcon className="h-4 w-4" />
            {pendingCount > 0 && (
                <span className="absolute -top-1 -right-1 bg-red-500 text-white text-[10px] w-4 h-4 flex items-center justify-center rounded-full border-2 border-white">
                    {pendingCount}
                </span>
            )}
        </Button>
    );
}
