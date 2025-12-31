import { useState, useMemo } from 'react';
import {
    Dialog,
    DialogContent,
    DialogHeader,
    DialogTitle,
    DialogDescription
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { useQuery } from '@tanstack/react-query';
import { format, parseISO } from 'date-fns';
import { apiRequest } from '@/lib/queryClient';
import { Loader2, Calendar, Clock, MapPin, ExternalLink } from "lucide-react";
import { AppointmentDialog } from './AppointmentDialog';
import { Deal } from '@shared/schema';

interface AppointmentHistoryDialogProps {
    open: boolean;
    onOpenChange: (open: boolean) => void;
    deal: Deal | null;
}

export function AppointmentHistoryDialog({ open, onOpenChange, deal }: AppointmentHistoryDialogProps) {
    const [selectedProvider, setSelectedProvider] = useState<'google' | 'zoho'>('google'); // Default to google for now
    const [editingEvent, setEditingEvent] = useState<any | null>(null);
    const [isEditModalOpen, setIsEditModalOpen] = useState(false);

    // Fetch events
    const { data: events = [], isLoading } = useQuery({
        queryKey: [`/api/${selectedProvider}/calendar/events`, selectedProvider],
        queryFn: async () => {
            // Fetch a broad range to find recent histry
            const start = new Date();
            start.setMonth(start.getMonth() - 1); // Last month
            const end = new Date();
            end.setMonth(end.getMonth() + 3); // Next 3 months

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
                const res = await apiRequest("GET", `/api/${selectedProvider}/calendar/events?${query.toString()}`);
                if (!res.ok) return [];
                const data = await res.json();
                return data.items || [];
            } catch (e) {
                return [];
            }
        },
        enabled: open && !!deal
    });

    const filteredEvents = useMemo(() => {
        if (!deal || !events || !Array.isArray(events)) return [];

        const dealData = deal as any;
        const contactEmail = dealData.contact?.email?.toLowerCase();
        const contactName = dealData.contact?.name?.toLowerCase();


        if (!contactEmail && !contactName) return [];

        return events.filter((event: any) => {
            const attendees = event.attendees || [];
            // Check if contact is an attendee
            const hasAttendee = attendees.some((a: any) => a.email?.toLowerCase() === contactEmail || a === contactEmail);

            // If contact has no email, fallback to checking if summary or description contains the name
            if (!contactEmail && contactName) {
                const nameParts = contactName.split(' ').filter((part: string) => part.length > 2);
                const summaryLower = event.summary?.toLowerCase() || '';
                const descriptionLower = event.description?.toLowerCase() || '';

                const nameMatch = nameParts.some((part: string) =>
                    summaryLower.includes(part) || descriptionLower.includes(part)
                );
                return nameMatch;
            }

            return hasAttendee;
        })
            .sort((a: any, b: any) => new Date(b.start.dateTime || b.start.date).getTime() - new Date(a.start.dateTime || a.start.date).getTime())
            .slice(0, 3); // Last 3
    }, [events, deal]);

    const handleEditClick = (event: any) => {
        setEditingEvent(event);
        setIsEditModalOpen(true);
    };

    return (
        <>
            <Dialog open={open} onOpenChange={onOpenChange}>
                <DialogContent className="sm:max-w-[500px]">
                    <DialogHeader>
                        <DialogTitle>Historial de Citas</DialogTitle>
                        <DialogDescription>
                            Mostrando últimas 3 citas para {(deal as any)?.contact?.name}
                        </DialogDescription>
                    </DialogHeader>

                    <div className="flex gap-2 mb-4 justify-end">
                        <div className="flex bg-gray-100 p-1 rounded-lg">
                            <button
                                className={`px-3 py-1 text-sm rounded-md transition-all ${selectedProvider === 'google' ? 'bg-white shadow text-blue-600 font-medium' : 'text-gray-500'}`}
                                onClick={() => setSelectedProvider('google')}
                            >
                                Google
                            </button>
                            <button
                                className={`px-3 py-1 text-sm rounded-md transition-all ${selectedProvider === 'zoho' ? 'bg-white shadow text-orange-600 font-medium' : 'text-gray-500'}`}
                                onClick={() => setSelectedProvider('zoho')}
                            >
                                Zoho
                            </button>
                        </div>
                    </div>

                    <div className="space-y-3">
                        {isLoading ? (
                            <div className="flex justify-center py-8">
                                <Loader2 className="h-6 w-6 animate-spin text-gray-400" />
                            </div>
                        ) : filteredEvents.length === 0 ? (
                            <div className="text-center py-8 text-gray-500 text-sm">
                                <Calendar className="h-8 w-8 mx-auto mb-2 opacity-20" />
                                No se encontraron citas recientes.
                            </div>
                        ) : (
                            filteredEvents.map((event: any) => (
                                <div key={event.id} className="border rounded-lg p-3 hover:bg-gray-50 transition-colors group relative">
                                    <div className="flex justify-between items-start mb-1">
                                        <h4 className="font-medium text-sm text-gray-900">{event.summary}</h4>
                                        <Button
                                            variant="ghost"
                                            size="sm"
                                            className="h-6 w-6 p-0 opacity-0 group-hover:opacity-100"
                                            onClick={() => handleEditClick(event)}
                                            title="Editar Cita"
                                        >
                                            <ExternalLink className="h-3 w-3 text-blue-500" />
                                        </Button>
                                    </div>
                                    <div className="flex items-center gap-2 text-xs text-gray-500 mb-1">
                                        <Calendar className="h-3 w-3" />
                                        {format(parseISO(event.start.dateTime || event.start.date), "d MMM yyyy")}
                                    </div>
                                    <div className="flex items-center gap-2 text-xs text-gray-500">
                                        <Clock className="h-3 w-3" />
                                        {format(parseISO(event.start.dateTime || event.start.date), "HH:mm")} -
                                        {format(parseISO(event.end.dateTime || event.end.date), "HH:mm")}
                                    </div>
                                    {event.location && (
                                        <div className="flex items-center gap-2 text-xs text-gray-500 mt-1">
                                            <MapPin className="h-3 w-3" />
                                            {event.location}
                                        </div>
                                    )}
                                </div>
                            ))
                        )}
                    </div>
                </DialogContent>
            </Dialog>

            {editingEvent && (
                <AppointmentDialog
                    open={isEditModalOpen}
                    onOpenChange={setIsEditModalOpen}
                    initialData={{
                        summary: editingEvent.summary,
                        description: editingEvent.description,
                        location: editingEvent.location,
                        startDateTime: editingEvent.start.dateTime || editingEvent.start.date,
                        endDateTime: editingEvent.end.dateTime || editingEvent.end.date,
                        attendees: editingEvent.attendees?.map((a: any) => a.email || a) || [],
                        eventId: editingEvent.id,
                        provider: selectedProvider
                    }}
                    onSuccess={() => {
                        setIsEditModalOpen(false);
                        // Invalidate queries handled by parent or react-query automatically if keys match
                    }}
                />
            )}
        </>
    );
}
