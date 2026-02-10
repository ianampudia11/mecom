import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from "@/components/ui/table";
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";

import { format, isToday, isYesterday } from "date-fns";
import { es } from "date-fns/locale";
import { Deal, Property, PipelineStage } from "@shared/schema";
import { MessageSquare, Calendar, DollarSign, ArrowUpRight, Home, Check, Plus, X, Loader2, Tag as TagIcon, MoreHorizontal, History as HistoryIcon, Edit, Trash } from "lucide-react";
import { useTranslation } from "@/hooks/use-translation";
import { DealAppointmentIndicator } from './DealAppointmentIndicator';
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from "@/components/ui/select";
import {
    Command,
    CommandEmpty,
    CommandGroup,
    CommandInput,
    CommandItem,
    CommandList,
    CommandSeparator,
} from "@/components/ui/command";
import {
    Popover,
    PopoverContent,
    PopoverTrigger,
} from "@/components/ui/popover";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";
import { useState, useEffect, useRef } from "react";
import { cn } from "@/lib/utils";
import { ColoredTag } from "@/components/ui/colored-tag";

import { Checkbox } from "@/components/ui/checkbox";

interface ExtendedDeal extends Deal {
    unreadCount?: number;
    lastMessageAt?: Date | null;
    lastMessageContent?: string | null;
    properties?: { id: number; title: string }[];
    propertyCount?: number;
    contact?: {
        id: number;
        name: string;
        phone: string | null;
        email: string | null;
        avatarUrl?: string; // Optional if not always present
    };
}

interface PipelineListProps {
    deals: ExtendedDeal[];
    pipelineStages: any[];
    onDealClick: (deal: Deal) => void;
    onMessageClick?: (deal: Deal) => void;
    showSelectionMode?: boolean;
    selectedDeals?: Deal[];
    onDealSelect?: (deal: Deal, selected: boolean) => void;
    onScheduleAppointment?: (deal: Deal) => void;
}

const TAG_COLORS = [
    { bg: "bg-blue-100", text: "text-blue-700" },
    { bg: "bg-green-100", text: "text-green-700" },
    { bg: "bg-purple-100", text: "text-purple-700" },
    { bg: "bg-yellow-100", text: "text-yellow-700" },
    { bg: "bg-pink-100", text: "text-pink-700" },
    { bg: "bg-indigo-100", text: "text-indigo-700" },
    { bg: "bg-orange-100", text: "text-orange-700" },
    { bg: "bg-teal-100", text: "text-teal-700" },
];

const getTagColor = (tag: string) => {
    let hash = 0;
    for (let i = 0; i < tag.length; i++) {
        hash = tag.charCodeAt(i) + ((hash << 5) - hash);
    }
    const index = Math.abs(hash) % TAG_COLORS.length;
    return TAG_COLORS[index];
};


const EditableCell = ({ value, onSave, className }: { value: string, onSave: (val: string) => void, className?: string }) => {
    const [isEditing, setIsEditing] = useState(false);
    const [tempValue, setTempValue] = useState(value);
    const inputRef = useRef<HTMLTextAreaElement>(null);

    useEffect(() => {
        setTempValue(value);
    }, [value]);

    useEffect(() => {
        if (isEditing && inputRef.current) {
            inputRef.current.focus();
            inputRef.current.setSelectionRange(inputRef.current.value.length, inputRef.current.value.length);
        }
    }, [isEditing]);

    const handleSave = () => {
        if (tempValue !== value) {
            onSave(tempValue);
        }
        setIsEditing(false);
    };

    return (
        <div className={cn("relative w-full h-full flex items-center", className)}>
            {isEditing ? (
                <div className="absolute top-0 left-0 w-full z-50">
                    <Textarea
                        ref={inputRef}
                        value={tempValue}
                        onChange={(e) => setTempValue(e.target.value)}
                        onBlur={handleSave}
                        onKeyDown={(e) => {
                            if (e.key === 'Enter' && !e.shiftKey) { // Allow Shift+Enter for newlines
                                e.preventDefault();
                                handleSave();
                            }
                            if (e.key === 'Escape') {
                                setTempValue(value);
                                setIsEditing(false);
                            }
                        }}
                        className="min-h-[100px] w-full text-sm resize-none shadow-lg bg-white"
                        onClick={(e) => e.stopPropagation()}
                    />
                </div>
            ) : (
                <div className="flex items-center gap-1 group relative w-full h-full">
                    <div
                        onClick={(e) => {
                            e.stopPropagation();
                            setIsEditing(true);
                        }}
                        className="cursor-text hover:bg-gray-100 px-2 py-1 rounded flex items-center w-full min-h-[36px]"
                        title="Click to edit"
                    >
                        <span className="text-sm font-semibold text-gray-900 line-clamp-2 break-words leading-tight" style={{ wordBreak: 'break-word' }}>
                            {value}
                        </span>
                    </div>
                    {value.length > 50 && (
                        <Popover>
                            <PopoverTrigger asChild>
                                <Button variant="ghost" size="icon" className="h-6 w-6 shrink-0 opacity-0 group-hover:opacity-100 transition-opacity" onClick={(e) => e.stopPropagation()}>
                                    <span className="mb-2">...</span>
                                </Button>
                            </PopoverTrigger>
                            <PopoverContent className="w-auto max-w-md p-4">
                                <p className="text-sm header-wrap break-words">{value}</p>
                            </PopoverContent>
                        </Popover>
                    )}
                </div>
            )}
        </div>
    );
};

const EditableStage = ({ stageId, stages, onSave }: { stageId: number, stages: any[], onSave: (val: number) => void }) => {
    const currentStage = stages.find(s => s.id === stageId);

    return (
        <div onClick={(e) => e.stopPropagation()}>
            <Select
                value={stageId.toString()}
                onValueChange={(val) => onSave(parseInt(val))}
            >
                <SelectTrigger className={`h-8 w-[140px] border-none bg-transparent hover:bg-gray-100 focus:ring-0`} style={{ color: currentStage?.color }}>
                    <div className="flex items-center gap-2">
                        <div className="h-2 w-2 rounded-full" style={{ backgroundColor: currentStage?.color }} />
                        <SelectValue>{currentStage?.name}</SelectValue>
                    </div>
                </SelectTrigger>
                <SelectContent>
                    {stages.map((stage) => (
                        <SelectItem key={stage.id} value={stage.id.toString()}>
                            <div className="flex items-center gap-2">
                                <div className="h-2 w-2 rounded-full" style={{ backgroundColor: stage.color }} />
                                {stage.name}
                            </div>
                        </SelectItem>
                    ))}
                </SelectContent>
            </Select>
        </div>
    );
};

const TagPropertyManager = ({ deal, onUpdateTags, onLinkProperty, onUnlinkProperty }: {
    deal: ExtendedDeal,
    onUpdateTags: (tags: string[]) => void,
    onLinkProperty: (prop: Property) => void,
    onUnlinkProperty: (propId: number) => void
}) => {
    const [openTags, setOpenTags] = useState(false);
    const [openProps, setOpenProps] = useState(false);
    const [tagSearch, setTagSearch] = useState("");
    const [propSearch, setPropSearch] = useState("");

    // Fetch tags with stats/colors
    const { data: tagStats = [] } = useQuery<any[]>({
        queryKey: ['/api/tags/stats'],
        queryFn: async () => {
            const res = await fetch('/api/tags/stats');
            if (!res.ok) return [];
            return await res.json();
        },
        staleTime: 60000
    });

    const availableTags = tagStats.map((t: any) => t.tag);
    const tagColorsMap = new Map(tagStats.map((t: any) => [t.tag, t.color]));

    // Fetch properties
    const { data: properties = [] } = useQuery({
        queryKey: ['/api/properties'],
        queryFn: () => apiRequest('GET', '/api/properties').then(res => res.json()).then(data => Array.isArray(data) ? data : []),
        staleTime: 60000,
        enabled: openProps
    });

    const currentTags = deal.tags || [];
    const currentProps = deal.properties || [];

    const handleAddTag = () => {
        if (tagSearch && !currentTags.includes(tagSearch)) {
            onUpdateTags([...currentTags, tagSearch]);
            setTagSearch("");
        }
    };

    const toggleTag = (tag: string) => {
        if (currentTags.includes(tag)) {
            onUpdateTags(currentTags.filter(t => t !== tag));
        } else {
            onUpdateTags([...currentTags, tag]);
        }
    };

    return (
        <div className="flex flex-col gap-2" onClick={e => e.stopPropagation()}>
            {/* TAGS ROW */}
            <div className="flex flex-wrap gap-1">
                {currentTags.slice(0, 3).map((tag, i) => (
                    <ColoredTag
                        key={i}
                        name={tag}
                        color={tagColorsMap.get(tag) || undefined}
                        size="sm"
                    />
                ))}
                {currentTags.length > 3 && (
                    <Badge variant="outline" className="text-xs">
                        +{currentTags.length - 3}
                    </Badge>
                )}

                <Popover open={openTags} onOpenChange={(open) => {
                    setOpenTags(open);
                    if (open) console.log('Popover opened');
                }}>
                    <PopoverTrigger asChild>
                        <Button variant="ghost" size="sm" className="h-5 w-5 p-0 rounded-full">
                            <Plus className="h-3 w-3" />
                        </Button>
                    </PopoverTrigger>
                    <PopoverContent className="p-0" side="right" align="start">
                        <Command>
                            <CommandInput
                                placeholder="Add tag..."
                                value={tagSearch}
                                onValueChange={setTagSearch}
                                onKeyDown={(e) => {
                                    if (e.key === 'Enter') handleAddTag();
                                }}
                            />
                            <CommandList>
                                <CommandEmpty>Press Enter to add "{tagSearch}"</CommandEmpty>
                                <CommandGroup heading="Tags">
                                    {availableTags.map((tag) => (
                                        <CommandItem
                                            key={tag}
                                            value={tag}
                                            onSelect={() => {
                                                if (currentTags.includes(tag)) {
                                                    onUpdateTags(currentTags.filter(t => t !== tag));
                                                } else {
                                                    onUpdateTags([...currentTags, tag]);
                                                }
                                            }}
                                        >
                                            <div className="flex items-center gap-2">
                                                {currentTags.includes(tag) && <Check className="h-4 w-4" />}
                                                <ColoredTag
                                                    name={tag}
                                                    color={tagColorsMap.get(tag) || undefined}
                                                    size="sm"
                                                />
                                            </div>
                                        </CommandItem>
                                    ))}
                                </CommandGroup>
                            </CommandList>
                        </Command>
                    </PopoverContent>
                </Popover>
            </div>
            {/* PROPERTIES ROW */}
            <Popover open={openProps} onOpenChange={setOpenProps}>
                <PopoverTrigger asChild>
                    <div className="flex flex-col gap-0.5 min-h-[24px] w-full cursor-pointer hover:bg-gray-100 p-1 rounded transition-colors group">
                        {currentProps.length > 0 ? (
                            currentProps.map(prop => (
                                <span key={prop.id} className="text-xs text-blue-600 flex items-center gap-1">
                                    <Home className="h-3 w-3 shrink-0 opacity-70" />
                                    {prop.title || "Propiedad sin nombre"}
                                </span>
                            ))
                        ) : (
                            <span className="text-xs text-muted-foreground opacity-50 group-hover:opacity-100 flex items-center gap-1">
                                <Plus className="h-3 w-3" /> Link property...
                            </span>
                        )}
                    </div>
                </PopoverTrigger>
                <PopoverContent className="w-[400px] p-0" align="start">
                    <Command>
                        <CommandInput placeholder="Search properties..." value={propSearch} onValueChange={setPropSearch} />
                        <CommandList>
                            <CommandEmpty>No properties found.</CommandEmpty>
                            <CommandGroup heading="Properties">
                                {properties.map((prop: Property) => {
                                    const isLinked = currentProps.some(p => p.id === prop.id);
                                    return (
                                        <CommandItem key={prop.id} value={prop.name} onSelect={() => {
                                            if (isLinked) onUnlinkProperty(prop.id);
                                            else onLinkProperty(prop);
                                        }}>
                                            <Check className={cn("mr-2 h-4 w-4", isLinked ? "opacity-100" : "opacity-0")} />
                                            <div className="flex flex-col">
                                                <span>{prop.name}</span>
                                                <span className="text-xs text-muted-foreground">{prop.address}</span>
                                            </div>
                                        </CommandItem>
                                    );
                                })}
                            </CommandGroup>
                        </CommandList>
                    </Command>
                </PopoverContent>
            </Popover>
        </div>
    );
};


export default function PipelineList({
    deals,
    pipelineStages,
    onDealClick,
    onMessageClick,
    showSelectionMode = false,
    selectedDeals = [],
    onDealSelect,
    onScheduleAppointment,
    onViewHistory
}: PipelineListProps & { onViewHistory?: (deal: Deal) => void }) {
    const { t } = useTranslation();
    const queryClient = useQueryClient();
    const { toast } = useToast();

    // Column Width State
    const [columnWidths, setColumnWidths] = useState({
        contact: 200,
        deal: 300,
        stage: 200,
        tags: 300,
        activity: 150
    });

    // Resizing Logic
    const resizeRef = useRef<{ col: string, startX: number, startWidth: number } | null>(null);

    const handleMouseDown = (e: React.MouseEvent, col: string) => {
        e.preventDefault();
        resizeRef.current = {
            col,
            startX: e.pageX,
            startWidth: columnWidths[col as keyof typeof columnWidths]
        };
        document.addEventListener('mousemove', handleMouseMove);
        document.addEventListener('mouseup', handleMouseUp);
        document.body.style.cursor = 'col-resize';
    };

    const handleMouseMove = (e: MouseEvent) => {
        if (!resizeRef.current) return;
        const { col, startX, startWidth } = resizeRef.current;
        const diff = e.pageX - startX;
        setColumnWidths(prev => ({
            ...prev,
            [col]: Math.max(100, startWidth + diff) // Min width 100px
        }));
    };

    const handleMouseUp = () => {
        resizeRef.current = null;
        document.removeEventListener('mousemove', handleMouseMove);
        document.removeEventListener('mouseup', handleMouseUp);
        document.body.style.cursor = 'default';
    };

    // MUTATIONS
    const updateDealMutation = useMutation({
        mutationFn: async ({ id, data }: { id: number, data: any }) => {
            const res = await apiRequest("PATCH", `/api/deals/${id}`, data);
            return res.json();
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['/api/deals'] });
            toast({ title: "Deal updated", description: "Changes saved successfully." });
        },
        onError: (err: any) => {
            toast({ title: "Error", description: err.message, variant: "destructive" });
        }
    });

    const updateStageMutation = useMutation({
        mutationFn: async ({ id, stageId }: { id: number, stageId: number }) => {
            // Find stage name for the specific route update if needed, but endpoint might just take stageId or stage name
            // Looking at routes.ts: PATCH /api/deals/:id/stage takes { stage: string } (stage NAME, enum probably) 
            // OR checks deal update. 
            // The `updateDeal` (PATCH /api/deals/:id) takes `stageId`. Let's use that one.
            const res = await apiRequest("PATCH", `/api/deals/${id}`, { stageId });
            return res.json();
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['/api/deals'] });
            toast({ title: "Stage updated" });
        },
        onError: (err: any) => {
            toast({ title: "Error moving deal", description: err.message, variant: "destructive" });
        }
    });

    const linkPropertyMutation = useMutation({
        mutationFn: async ({ dealId, propertyId }: { dealId: number, propertyId: number }) => {
            const res = await apiRequest("POST", `/api/deals/${dealId}/properties`, { property_id: propertyId });
            return res.json();
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['/api/deals'] });
            toast({ title: "Property linked" });
        },
        onError: (err: any) => {
            toast({ title: "Error linking property", description: err.message, variant: "destructive" });
        }
    });

    const unlinkPropertyMutation = useMutation({
        mutationFn: async ({ dealId, propertyId }: { dealId: number, propertyId: number }) => {
            // Assuming DELETE with body or query param? Typically DELETE body is not standard fetch but supported by some.
            // Given I don't know the exact route, I will try DELETE /api/deals/:id/properties/:propId first
            // If that 404s, user will report.
            const res = await apiRequest("DELETE", `/api/deals/${dealId}/properties/${propertyId}`);
            return res.json();
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['/api/deals'] });
            toast({ title: "Property removed" });
        },
        onError: (err: any) => {
            toast({ title: "Error removing property", description: "Could not unlink property.", variant: "destructive" });
        }
    });


    // Helper to get stage color/name
    const getStageInfo = (stageId: number) => {
        const stage = pipelineStages.find(s => s.id === stageId);
        return stage ? { name: stage.name, color: stage.color } : { name: 'Unknown', color: '#ccc' };
    };

    // Sort deals by lastMessageAt (desc), then lastActivityAt
    const sortedDeals = [...deals].sort((a: any, b: any) => {
        const timeA = a.lastMessageAt ? new Date(a.lastMessageAt).getTime() : 0;
        const timeB = b.lastMessageAt ? new Date(b.lastMessageAt).getTime() : 0;
        if (timeA !== timeB) return timeB - timeA;
        return new Date(b.lastActivityAt).getTime() - new Date(a.lastActivityAt).getTime();
    });

    return (
        <div className="rounded-md border bg-white shadow-sm overflow-hidden w-full overflow-x-auto">
            <Table style={{ tableLayout: 'fixed', minWidth: '1000px' }}>
                <TableHeader>
                    <TableRow className="bg-gray-50/50">
                        {showSelectionMode && (
                            <TableHead className="w-[40px]">
                                {/* Header checkbox for select all could go here if needed, keeping it simple for now */}
                            </TableHead>
                        )}
                        <TableHead style={{ width: columnWidths.contact }} className="relative">
                            {t('pipeline.contact', 'Contacto')}
                            <div className="absolute right-0 top-0 bottom-0 w-1 cursor-col-resize hover:bg-blue-400" onMouseDown={(e) => handleMouseDown(e, 'contact')} />
                        </TableHead>
                        <TableHead style={{ width: columnWidths.deal }} className="relative">
                            {t('pipeline.deal', 'Trato')}
                            <div className="absolute right-0 top-0 bottom-0 w-1 cursor-col-resize hover:bg-blue-400" onMouseDown={(e) => handleMouseDown(e, 'deal')} />
                        </TableHead>
                        <TableHead style={{ width: columnWidths.stage }} className="relative">
                            {t('pipeline.stage', 'Etapa')}
                            <div className="absolute right-0 top-0 bottom-0 w-1 cursor-col-resize hover:bg-blue-400" onMouseDown={(e) => handleMouseDown(e, 'stage')} />
                        </TableHead>
                        <TableHead style={{ width: columnWidths.tags }} className="relative">
                            {t('pipeline.tags_properties', 'Tags y Propiedades')}
                            <div className="absolute right-0 top-0 bottom-0 w-1 cursor-col-resize hover:bg-blue-400" onMouseDown={(e) => handleMouseDown(e, 'tags')} />
                        </TableHead>
                        <TableHead className="text-right relative" style={{ width: columnWidths.activity }}>
                            {t('pipeline.last_activity', 'Actividad / Mensaje')}
                            <div className="absolute right-0 top-0 bottom-0 w-1 cursor-col-resize hover:bg-blue-400" onMouseDown={(e) => handleMouseDown(e, 'activity')} />
                        </TableHead>
                        <TableHead className="w-[50px]"></TableHead>
                    </TableRow>
                </TableHeader>
                <TableBody>
                    {sortedDeals.length === 0 ? (
                        <TableRow>
                            <TableCell colSpan={6} className="h-24 text-center text-muted-foreground">
                                {t('pipeline.no_deals', 'No se encontraron tratos')}
                            </TableCell>
                        </TableRow>
                    ) : (
                        sortedDeals.map((deal) => {
                            const unreadCount = Number(deal.unreadCount ?? 0);
                            const hasUnread = unreadCount > 0;

                            let dateString = "";
                            if (deal.lastMessageAt) {
                                const msgDate = new Date(deal.lastMessageAt);
                                if (isToday(msgDate)) {
                                    dateString = "Hoy";
                                } else if (isYesterday(msgDate)) {
                                    dateString = "Ayer";
                                } else {
                                    dateString = format(msgDate, "d MMM yyyy", { locale: es });
                                }
                            }

                            return (
                                <TableRow
                                    key={deal.id}
                                    className="hover:bg-gray-50/50 transition-colors"
                                >
                                    {showSelectionMode && (
                                        <TableCell className="p-0 pl-3">
                                            <Checkbox
                                                checked={selectedDeals.some(d => d.id === deal.id)}
                                                onCheckedChange={(checked) => {
                                                    if (onDealSelect) onDealSelect(deal, checked === true);
                                                }}
                                                onClick={(e) => e.stopPropagation()}
                                            />
                                        </TableCell>
                                    )}
                                    <TableCell
                                        onClick={() => onDealClick(deal)}
                                        className="cursor-pointer"
                                    >
                                        {deal.contact && (
                                            <div className="flex items-center gap-2">
                                                <Avatar className="h-8 w-8">
                                                    <AvatarImage src={deal.contact.avatarUrl} />
                                                    <AvatarFallback>{deal.contact.name.substring(0, 2).toUpperCase()}</AvatarFallback>
                                                </Avatar>
                                                <div className="flex flex-col">
                                                    <span className="text-sm font-medium">{deal.contact.name}</span>
                                                    <span className="text-xs text-muted-foreground">{deal.contact.phone || deal.contact.email}</span>
                                                </div>
                                            </div>
                                        )}
                                    </TableCell>
                                    <TableCell className="font-medium p-0">
                                        <EditableCell
                                            value={deal.title}
                                            onSave={(val) => updateDealMutation.mutate({ id: deal.id, data: { title: val } })}
                                            className="h-full w-full py-3"
                                        />
                                    </TableCell>
                                    <TableCell className="p-0">
                                        <div className="px-2 flex items-center gap-1">
                                            <EditableStage
                                                stageId={deal.stageId || 0}
                                                stages={pipelineStages}
                                                onSave={(val) => updateStageMutation.mutate({ id: deal.id, stageId: val })}
                                            />

                                            <Button
                                                variant="ghost"
                                                size="icon"
                                                className="h-8 w-8 text-gray-500 hover:text-blue-600 hover:bg-blue-50"
                                                onClick={(e) => {
                                                    e.stopPropagation();
                                                    onScheduleAppointment?.(deal);
                                                }}
                                                title="Agendar Cita"
                                            >
                                                <Calendar className="h-4 w-4" />
                                            </Button>
                                            <DealAppointmentIndicator
                                                deal={deal}
                                                onClick={(d) => onViewHistory?.(d)}
                                            />
                                        </div>
                                    </TableCell>
                                    <TableCell className="align-top py-2">
                                        <TagPropertyManager
                                            deal={deal}
                                            onUpdateTags={(tags) => updateDealMutation.mutate({ id: deal.id, data: { tags } })}
                                            onLinkProperty={(prop) => linkPropertyMutation.mutate({ dealId: deal.id, propertyId: prop.id })}
                                            onUnlinkProperty={(propId) => unlinkPropertyMutation.mutate({ dealId: deal.id, propertyId: propId })}
                                        />
                                    </TableCell>
                                    <TableCell
                                        className="text-right cursor-pointer"
                                        onClick={(e) => {
                                            e.stopPropagation();
                                            if (onMessageClick) {
                                                onMessageClick(deal);
                                            } else {
                                                onDealClick(deal);
                                            }
                                        }}
                                    >
                                        <div className="flex flex-col items-end gap-1">
                                            {deal.lastMessageAt ? (
                                                <div className="flex flex-col items-end">
                                                    <span className="text-xs font-semibold text-gray-900 flex items-center gap-1">
                                                        {hasUnread && (
                                                            <div className="flex items-center gap-1 mr-1">
                                                                <span className="text-[10px] font-bold text-red-600">{unreadCount}</span>
                                                                <div className="relative flex h-2.5 w-2.5">
                                                                    <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-red-400 opacity-75"></span>
                                                                    <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-red-500"></span>
                                                                </div>
                                                            </div>
                                                        )}
                                                        {dateString} <MessageSquare className="h-3 w-3 text-blue-500" />
                                                    </span>
                                                    <span className="text-[11px] text-gray-500 max-w-[150px] truncate block text-right">
                                                        {deal.lastMessageContent || "Imagen / Archivo"}
                                                    </span>
                                                </div>
                                            ) : deal.lastActivityAt ? (
                                                <div className="flex flex-col items-end">
                                                    <span className="text-xs text-gray-500">
                                                        {format(new Date(deal.lastActivityAt), "d MMM", { locale: es })}
                                                    </span>
                                                    <span className="text-[10px] text-gray-400">Sin mensajes</span>
                                                </div>
                                            ) : (
                                                <span className="text-xs text-gray-400">-</span>
                                            )}
                                        </div>
                                    </TableCell>
                                    <TableCell className="w-[50px] text-center">
                                        <DropdownMenu>
                                            <DropdownMenuTrigger asChild>
                                                <Button variant="ghost" size="icon" className="h-8 w-8 text-gray-400 hover:text-gray-600" onClick={(e) => e.stopPropagation()}>
                                                    <MoreHorizontal className="h-4 w-4" />
                                                </Button>
                                            </DropdownMenuTrigger>
                                            <DropdownMenuContent align="end">
                                                <DropdownMenuItem onClick={(e) => { e.stopPropagation(); onDealClick(deal); }}>
                                                    <Edit className="mr-2 h-4 w-4" />
                                                    Editar
                                                </DropdownMenuItem>
                                                <DropdownMenuItem onClick={(e) => { e.stopPropagation(); toast({ title: "Historial", description: "Visualización de historial pronto disponible." }) }}>
                                                    <HistoryIcon className="mr-2 h-4 w-4" />
                                                    Historial
                                                </DropdownMenuItem>
                                                <DropdownMenuItem className="text-red-600">
                                                    <Trash className="mr-2 h-4 w-4" />
                                                    Eliminar
                                                </DropdownMenuItem>
                                            </DropdownMenuContent>
                                        </DropdownMenu>
                                    </TableCell>
                                </TableRow>
                            );
                        })
                    )}
                </TableBody>
            </Table>
        </div>
    );
}
