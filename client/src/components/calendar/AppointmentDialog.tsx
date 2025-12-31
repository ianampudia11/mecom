import { useState, useEffect, useRef } from 'react';
import {
    Dialog,
    DialogContent,
    DialogHeader,
    DialogTitle,
    DialogDescription
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue
} from "@/components/ui/select";
import { useTranslation } from '@/hooks/use-translation';
import { useToast } from '@/hooks/use-toast';
import { useMutation, useQuery } from '@tanstack/react-query';
import { queryClient, apiRequest } from '@/lib/queryClient';
import { formatISO, addHours } from 'date-fns';
import { useGoogleCalendarAuth } from '@/hooks/useGoogleCalendarAuth';
import { useZohoCalendarAuth } from '@/hooks/useZohoCalendarAuth';
import { useCalendlyCalendarAuth } from '@/hooks/useCalendlyCalendarAuth';
import { Loader2 } from 'lucide-react';

interface AppointmentDialogProps {
    open: boolean;
    onOpenChange: (open: boolean) => void;
    initialData?: {
        summary?: string;
        description?: string;
        attendees?: string[];
        location?: string;
        startDateTime?: string;
        endDateTime?: string;
        colorId?: string;
        eventId?: string; // If present, mode is EDIT
        provider?: 'google' | 'zoho' | 'calendly';
    };
    onSuccess?: () => void;
}

interface EventFormData {
    summary: string;
    description: string;
    location: string;
    startDateTime: string;
    endDateTime: string;
    attendees: string[];
    attendeeInput: string;
    colorId?: string;
}

export function AppointmentDialog({ open, onOpenChange, initialData, onSuccess }: AppointmentDialogProps) {
    const { t } = useTranslation();
    const { toast } = useToast();

    const { isConnected: isGoogleConnected } = useGoogleCalendarAuth();
    const { isConnected: isZohoConnected } = useZohoCalendarAuth();
    const { isConnected: isCalendlyConnected } = useCalendlyCalendarAuth();

    const [selectedProvider, setSelectedProvider] = useState<'google' | 'zoho' | 'calendly'>('google');
    const prevOpenRef = useRef(open);

    // Fetch Google Calendars
    const { data: googleCalendars = [] } = useQuery({
        queryKey: ['/api/google/calendars'],
        queryFn: async () => {
            const res = await apiRequest('GET', '/api/google/calendars');
            if (!res.ok) return [];
            const data = await res.json();
            return data.items || [];
        },
        enabled: isGoogleConnected && open
    });


    const defaultCalendarId = localStorage.getItem('defaultGoogleCalendarId') || 'primary';

    const [eventForm, setEventForm] = useState<EventFormData & { calendarId?: string }>({
        summary: '',
        description: '',
        location: '',
        startDateTime: formatISO(new Date()),
        endDateTime: formatISO(addHours(new Date(), 1)),
        attendees: [],
        attendeeInput: '',
        colorId: '1',
        calendarId: defaultCalendarId
    });

    // Default to first connected provider
    useEffect(() => {
        if (open && !prevOpenRef.current) {
            // Only set default provider if not editing and opening fresh
            if (!initialData?.eventId) {
                if (isGoogleConnected) setSelectedProvider('google');
                else if (isZohoConnected) setSelectedProvider('zoho');
                else if (isCalendlyConnected) setSelectedProvider('calendly');
            }
        }
    }, [open, isGoogleConnected, isZohoConnected, isCalendlyConnected, initialData]);

    // Handle initial data population - ONLY when modal opens
    useEffect(() => {
        if (open && !prevOpenRef.current && initialData) {
            const initialCalendarId = (initialData as any).calendarId || defaultCalendarId;

            setEventForm(prev => ({
                ...prev,
                summary: initialData.summary || prev.summary,
                description: initialData.description || prev.description,
                location: initialData.location || prev.location,
                attendees: initialData.attendees || prev.attendees,
                startDateTime: initialData.startDateTime || formatISO(new Date()),
                endDateTime: initialData.endDateTime || formatISO(addHours(new Date(), 1)),
                colorId: initialData.colorId || prev.colorId,
                calendarId: initialCalendarId
            }));

            if (initialData.provider) {
                setSelectedProvider(initialData.provider);
            }
        }
        prevOpenRef.current = open;
    }, [open, initialData, defaultCalendarId]);

    const isEditMode = !!initialData?.eventId;

    console.log('AppointmentDialog: googleCalendars', googleCalendars);
    console.log('AppointmentDialog: selectedProvider', selectedProvider);
    console.log('AppointmentDialog: isEditMode', isEditMode);

    // Create Event Mutation
    const createEventMutation = useMutation({
        mutationFn: async (data: any) => {
            const response = await apiRequest('POST', `/api/${selectedProvider}/calendar/events`, data);
            return response.json();
        },
        onSuccess: () => {
            toast({
                title: t('calendar.event_created', 'Event Created'),
                description: t('calendar.appointment_created_success', 'Your appointment has been successfully created'),
            });
            onOpenChange(false);
            onSuccess?.();
            queryClient.invalidateQueries({ queryKey: [`/api/${selectedProvider}/calendar/events`] });
            resetForm();
        },
        onError: (error: any) => {
            toast({
                title: t('common.error', 'Error'),
                description: t('calendar.event_create_failed', 'Failed to create event: {{error}}', { error: error.message }),
                variant: "destructive",
            });
        }
    });

    // Update Event Mutation
    const updateEventMutation = useMutation({
        mutationFn: async (data: any) => {
            const response = await apiRequest('PATCH', `/api/${selectedProvider}/calendar/events/${initialData?.eventId}`, data);
            return response.json();
        },
        onSuccess: () => {
            toast({
                title: t('calendar.event_updated', 'Event Updated'),
                description: t('calendar.appointment_updated_success', 'Your appointment has been successfully updated'),
            });
            onOpenChange(false);
            onSuccess?.();
            queryClient.invalidateQueries({ queryKey: [`/api/${selectedProvider}/calendar/events`] });
            resetForm();
        },
        onError: (error: any) => {
            toast({
                title: t('common.error', 'Error'),
                description: t('calendar.event_update_failed', 'Failed to update event: {{error}}', { error: error.message }),
                variant: "destructive",
            });
        }
    });

    const resetForm = () => {
        setEventForm({
            summary: '',
            description: '',
            location: '',
            startDateTime: formatISO(new Date()),
            endDateTime: formatISO(addHours(new Date(), 1)),
            attendees: [],
            attendeeInput: '',
            colorId: '1'
        });
    }

    const handleSubmit = () => {
        if (selectedProvider === 'calendly' && !isEditMode) { // Allow editing if somehow supported, but usually readonly
            // Calendly is strictly readonly for creation via API usually, but let's keep consistency
            toast({
                title: t('calendar.calendly_readonly', 'Calendly is Read-Only'),
                description: t('calendar.calendly_readonly_desc', 'You can view and cancel Calendly events, but cannot create new ones. Please use your Calendly dashboard to create events.'),
                variant: "destructive",
            });
            return;
        }
        // If editing and provider is calendly, block too
        if (isEditMode && selectedProvider === 'calendly') {
            toast({
                title: t('calendar.calendly_readonly', 'Simple Read-Only'),
                description: 'Cannot edit Calendly events via this interface.',
                variant: "destructive"
            });
            return;
        }

        if (!eventForm.summary || !eventForm.startDateTime || !eventForm.endDateTime) {
            toast({
                title: t('common.missing_information', 'Missing Information'),
                description: t('common.fill_required_fields', 'Please fill in all required fields'),
                variant: "destructive",
            });
            return;
        }

        const eventData = {
            summary: eventForm.summary,
            description: eventForm.description,
            location: eventForm.location,
            startDateTime: formatISO(new Date(eventForm.startDateTime)),
            endDateTime: formatISO(new Date(eventForm.endDateTime)),
            attendees: eventForm.attendees,
            colorId: eventForm.colorId,
            calendarId: eventForm.calendarId // Pass selected calendarId
        };

        if (isEditMode) {
            updateEventMutation.mutate(eventData);
        } else {
            createEventMutation.mutate(eventData);
        }
    };

    const isPending = createEventMutation.isPending || updateEventMutation.isPending;

    const deleteEventMutation = useMutation({
        mutationFn: async () => {
            if (!initialData?.eventId) return;
            const res = await apiRequest("DELETE", `/api/${selectedProvider}/calendar/events/${initialData.eventId}`);
            if (!res.ok) {
                const error = await res.json();
                throw new Error(error.message || 'Failed to delete event');
            }
            return res.json();
        },
        onSuccess: () => {
            toast({
                title: t('calendar.event_deleted', 'Event Deleted'),
                description: t('calendar.appointment_deleted_success', 'The appointment has been deleted'),
            });
            onOpenChange(false);
            onSuccess?.();
            queryClient.invalidateQueries({ queryKey: [`/api/${selectedProvider}/calendar/events`] });
        },
        onError: (error: Error) => {
            toast({
                title: t('common.error', 'Error'),
                description: error.message,
                variant: "destructive"
            });
        }
    });

    return (
        <Dialog open={open} onOpenChange={onOpenChange}>
            <DialogContent className="sm:max-w-[600px] max-h-[90vh] overflow-y-auto">
                <DialogHeader>
                    <DialogTitle>
                        {isEditMode ? t('calendar.edit_appointment', 'Edit Appointment') : t('calendar.schedule_appointment', 'Schedule New Appointment')}
                        <span className="ml-2 text-sm font-normal text-muted-foreground">
                            via {selectedProvider === 'google' ? 'Google Calendar' : selectedProvider === 'zoho' ? 'Zoho Calendar' : 'Calendly'}
                        </span>
                    </DialogTitle>
                    <DialogDescription>
                        {isEditMode
                            ? t('calendar.edit_appointment_desc', 'Update the details of your appointment.')
                            : t('calendar.schedule_appointment_desc', 'Create a new event in your calendar.')}
                    </DialogDescription>
                </DialogHeader>

                <div className="grid gap-4 py-4">
                    {/* Calendar Selection (Only for Google and New Events for now) */}
                    {!isEditMode && selectedProvider === 'google' && googleCalendars.length > 0 && (
                        <div className="grid grid-cols-4 items-center gap-4">
                            <Label className="text-right">
                                Calendar
                            </Label>
                            <Select
                                value={eventForm.calendarId}
                                onValueChange={(value) => {
                                    setEventForm(prev => ({ ...prev, calendarId: value }));
                                    localStorage.setItem('defaultGoogleCalendarId', value);
                                }}
                            >
                                <SelectTrigger className="col-span-3">
                                    <SelectValue placeholder="Select calendar" />
                                </SelectTrigger>
                                <SelectContent>
                                    {googleCalendars.map((cal: any) => (
                                        <SelectItem key={cal.id} value={cal.id}>
                                            <div className="flex items-center gap-2">
                                                <div className="h-2 w-2 rounded-full" style={{ backgroundColor: cal.backgroundColor || '#4285F4' }} />
                                                {cal.summary}
                                                {cal.primary && <span className="text-xs text-muted-foreground ml-2">(Primary)</span>}
                                            </div>
                                        </SelectItem>
                                    ))}
                                </SelectContent>
                            </Select>
                        </div>
                    )}

                    {/* Provider Selection */}
                    <div className="grid grid-cols-4 items-center gap-4">
                        <Label className="text-right">Provider</Label>
                        <Select value={selectedProvider} onValueChange={(v: any) => setSelectedProvider(v)} disabled={isEditMode}>
                            <SelectTrigger className="col-span-3">
                                <SelectValue />
                            </SelectTrigger>
                            <SelectContent>
                                <SelectItem value="google">Google Calendar {isGoogleConnected && '✓'}</SelectItem>
                                <SelectItem value="zoho">Zoho Calendar {isZohoConnected && '✓'}</SelectItem>
                                <SelectItem value="calendly">Calendly {isCalendlyConnected && '✓'}</SelectItem>
                            </SelectContent>
                        </Select>
                    </div>

                    <div className="grid grid-cols-4 items-center gap-4">
                        <Label htmlFor="edit-summary" className="text-right">
                            {t('calendar.title', 'Title')}*
                        </Label>
                        <Input
                            id="edit-summary"
                            value={eventForm.summary}
                            onChange={(e) => setEventForm({ ...eventForm, summary: e.target.value })}
                            className="col-span-3"
                        />
                    </div>
                    <div className="grid grid-cols-4 items-center gap-4">
                        <Label htmlFor="edit-description" className="text-right">
                            {t('calendar.description', 'Description')}
                        </Label>
                        <Textarea
                            id="edit-description"
                            value={eventForm.description}
                            onChange={(e) => setEventForm({ ...eventForm, description: e.target.value })}
                            className="col-span-3 h-24"
                        />
                    </div>
                    <div className="grid grid-cols-4 items-center gap-4">
                        <Label htmlFor="location" className="text-right">
                            {t('calendar.location', 'Location')}
                        </Label>
                        <Input
                            id="location"
                            value={eventForm.location}
                            onChange={(e) => setEventForm({ ...eventForm, location: e.target.value })}
                            className="col-span-3"
                        />
                    </div>

                    <div className="grid grid-cols-4 items-center gap-4">
                        <Label htmlFor="colorId" className="text-right">
                            {t('calendar.category', 'Category')}
                        </Label>
                        <Select
                            value={eventForm.colorId}
                            onValueChange={(value) => setEventForm({ ...eventForm, colorId: value })}
                        >
                            <SelectTrigger className="col-span-3">
                                <SelectValue placeholder={t('calendar.select_category', 'Select category')} />
                            </SelectTrigger>
                            <SelectContent>
                                <SelectItem value="1">
                                    <div className="flex items-center">
                                        <div className="w-3 h-3 rounded-full bg-blue-500 mr-2"></div>
                                        <span>{t('calendar.color.blue', 'Blue')}</span>
                                    </div>
                                </SelectItem>
                                <SelectItem value="2">
                                    <div className="flex items-center">
                                        <div className="w-3 h-3 rounded-full bg-green-500 mr-2"></div>
                                        <span>{t('calendar.color.green', 'Green')}</span>
                                    </div>
                                </SelectItem>
                                <SelectItem value="3">
                                    <div className="flex items-center">
                                        <div className="w-3 h-3 rounded-full bg-purple-500 mr-2"></div>
                                        <span>{t('calendar.color.purple', 'Purple')}</span>
                                    </div>
                                </SelectItem>
                                <SelectItem value="4">
                                    <div className="flex items-center">
                                        <div className="w-3 h-3 rounded-full bg-red-500 mr-2"></div>
                                        <span>{t('calendar.color.red', 'Red')}</span>
                                    </div>
                                </SelectItem>
                                <SelectItem value="5">
                                    <div className="flex items-center">
                                        <div className="w-3 h-3 rounded-full bg-yellow-500 mr-2"></div>
                                        <span>{t('calendar.color.yellow', 'Yellow')}</span>
                                    </div>
                                </SelectItem>
                                <SelectItem value="6">
                                    <div className="flex items-center">
                                        <div className="w-3 h-3 rounded-full bg-orange-500 mr-2"></div>
                                        <span>{t('calendar.color.orange', 'Orange')}</span>
                                    </div>
                                </SelectItem>
                                <SelectItem value="7">
                                    <div className="flex items-center">
                                        <div className="w-3 h-3 rounded-full bg-cyan-500 mr-2"></div>
                                        <span>{t('calendar.color.turquoise', 'Turquoise')}</span>
                                    </div>
                                </SelectItem>
                                <SelectItem value="8">
                                    <div className="flex items-center">
                                        <div className="w-3 h-3 rounded-full bg-gray-500 mr-2"></div>
                                        <span>{t('calendar.color.gray', 'Gray')}</span>
                                    </div>
                                </SelectItem>
                            </SelectContent>
                        </Select>
                    </div>

                    <div className="grid grid-cols-4 items-center gap-4">
                        <Label htmlFor="startDateTime" className="text-right">
                            {t('calendar.start_time', 'Start Time')}*
                        </Label>
                        <Input
                            id="startDateTime"
                            type="datetime-local"
                            value={eventForm.startDateTime.slice(0, 16)}
                            onChange={(e) => setEventForm({ ...eventForm, startDateTime: e.target.value })}
                            className="col-span-3"
                        />
                    </div>
                    <div className="grid grid-cols-4 items-center gap-4">
                        <Label htmlFor="endDateTime" className="text-right">
                            {t('calendar.end_time', 'End Time')}*
                        </Label>
                        <Input
                            id="endDateTime"
                            type="datetime-local"
                            value={eventForm.endDateTime.slice(0, 16)}
                            onChange={(e) => setEventForm({ ...eventForm, endDateTime: e.target.value })}
                            className="col-span-3"
                        />
                    </div>

                    <div className="grid grid-cols-4 items-start gap-4">
                        <Label htmlFor="attendees" className="text-right pt-2">
                            {t('calendar.attendees', 'Attendees')}
                        </Label>
                        <div className="col-span-3 space-y-2">
                            <div className="flex space-x-2">
                                <Input
                                    id="attendees"
                                    placeholder="Enter email address"
                                    value={eventForm.attendeeInput}
                                    onChange={(e) => setEventForm({ ...eventForm, attendeeInput: e.target.value })}
                                    onKeyDown={(e) => {
                                        if (e.key === 'Enter') {
                                            e.preventDefault();
                                            if (eventForm.attendeeInput.trim() && !eventForm.attendees.includes(eventForm.attendeeInput.trim())) {
                                                setEventForm({
                                                    ...eventForm,
                                                    attendees: [...eventForm.attendees, eventForm.attendeeInput.trim()],
                                                    attendeeInput: ''
                                                });
                                            }
                                        }
                                    }}
                                />
                                <Button
                                    type="button"
                                    variant="secondary"
                                    onClick={() => {
                                        if (eventForm.attendeeInput.trim() && !eventForm.attendees.includes(eventForm.attendeeInput.trim())) {
                                            setEventForm({
                                                ...eventForm,
                                                attendees: [...eventForm.attendees, eventForm.attendeeInput.trim()],
                                                attendeeInput: ''
                                            });
                                        }
                                    }}
                                >
                                    {t('common.add', 'Add')}
                                </Button>
                            </div>

                            {eventForm.attendees.length > 0 && (
                                <div className="flex flex-wrap gap-2 mt-2">
                                    {eventForm.attendees.map((email) => (
                                        <div key={email} className="bg-gray-100 px-2 py-1 rounded-md text-sm flex items-center">
                                            <span>{email}</span>
                                            <button
                                                className="ml-2 text-gray-500 hover:text-red-500"
                                                onClick={() => setEventForm({
                                                    ...eventForm,
                                                    attendees: eventForm.attendees.filter(a => a !== email)
                                                })}
                                            >
                                                ×
                                            </button>
                                        </div>
                                    ))}
                                </div>
                            )}
                        </div>
                    </div>

                </div>

                <div className="flex justify-between items-center gap-2">
                    {isEditMode ? (
                        <Button
                            variant="destructive"
                            className="bg-red-500 hover:bg-red-600 text-white"
                            onClick={() => deleteEventMutation.mutate()}
                            disabled={deleteEventMutation.isPending}
                        >
                            {deleteEventMutation.isPending ? <Loader2 className="h-4 w-4 animate-spin" /> : t('common.delete', 'Eliminar')}
                        </Button>
                    ) : <div></div>}

                    <div className="flex gap-2">
                        <Button variant="outline" onClick={() => onOpenChange(false)}>
                            {t('common.cancel', 'Cancel')}
                        </Button>
                        <Button onClick={handleSubmit} disabled={isPending}>
                            {isPending ? (isEditMode ? 'Updating...' : 'Creating...') : (isEditMode ? 'Update Appointment' : 'Create Appointment')}
                        </Button>
                    </div>
                </div>
            </DialogContent >
        </Dialog >
    );
}
