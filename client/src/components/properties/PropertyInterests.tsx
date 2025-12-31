import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
    Home,
    Trash2,
    ExternalLink,
    Calendar,
    CheckCircle2,
    XCircle,
    HelpCircle,
    Clock
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from '@/components/ui/select';
import {
    Dialog,
    DialogContent,
    DialogHeader,
    DialogTitle,
    DialogTrigger,
} from '@/components/ui/dialog';
import { useToast } from '@/hooks/use-toast';
import { Badge } from '@/components/ui/badge';
import PropertySelector from './PropertySelector';

interface PropertyInterestsProps {
    dealId: number;
}

const interestLevels = {
    inquired: { label: 'Preguntó', color: 'bg-gray-100 text-gray-700', icon: HelpCircle },
    interested: { label: 'Interesado', color: 'bg-blue-100 text-blue-700', icon: CheckCircle2 },
    very_interested: { label: 'Muy Interesado', color: 'bg-green-100 text-green-700', icon: Star },
    scheduled_viewing: { label: 'Cita Agendada', color: 'bg-purple-100 text-purple-700', icon: Calendar },
    viewed: { label: 'Visitó', color: 'bg-indigo-100 text-indigo-700', icon: Eye },
    offer_made: { label: 'Hizo Oferta', color: 'bg-yellow-100 text-yellow-700', icon: FileText },
    rejected: { label: 'Descartada', color: 'bg-red-100 text-red-700', icon: XCircle },
    purchased: { label: 'Comprada', color: 'bg-emerald-100 text-emerald-700', icon: Award },
};

import { Star, Eye, FileText, Award } from 'lucide-react';

export default function PropertyInterests({ dealId }: PropertyInterestsProps) {
    const { toast } = useToast();
    const queryClient = useQueryClient();
    const [isDialogOpen, setIsDialogOpen] = useState(false);

    const { data: interests = [], isLoading } = useQuery({
        queryKey: ['deal-properties', dealId],
        queryFn: async () => {
            const res = await fetch(`/api/deals/${dealId}/properties`);
            if (!res.ok) throw new Error('Failed to fetch properties');
            return res.json();
        },
    });

    const linkMutation = useMutation({
        mutationFn: async (propertyId: number) => {
            const res = await fetch(`/api/deals/${dealId}/properties`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ property_id: propertyId }),
            });
            if (!res.ok) throw new Error('Failed to link property');
            return res.json();
        },
        onSuccess: () => {
            toast({ title: 'Propiedad vinculada exitosamente' });
            queryClient.invalidateQueries({ queryKey: ['deal-properties', dealId] });
            setIsDialogOpen(false);
        },
    });

    const updateStatusMutation = useMutation({
        mutationFn: async ({ interestId, status }: { interestId: number; status: string }) => {
            // Re-use link endpoint which handles updates if exists
            // But we need property_id, so actually better to call link endpoint 
            // Wait, the API design was post /deals/:id/properties for create/update
            // Let's use that one, need to find the property_id from the interest list
            const interest = interests.find((i: any) => i.id === interestId);
            if (!interest) throw new Error('Interest not found');

            const res = await fetch(`/api/deals/${dealId}/properties`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    property_id: interest.property_id,
                    status: status
                }),
            });
            if (!res.ok) throw new Error('Failed to update status');
            return res.json();
        },
        onSuccess: () => {
            toast({ title: 'Estado actualizado' });
            queryClient.invalidateQueries({ queryKey: ['deal-properties', dealId] });
        },
    });

    const unlinkMutation = useMutation({
        mutationFn: async (interestId: number) => {
            const res = await fetch(`/api/interests/${interestId}`, {
                method: 'DELETE',
            });
            if (!res.ok) throw new Error('Failed to unlink property');
            return res.json();
        },
        onSuccess: () => {
            toast({ title: 'Propiedad desvinculada' });
            queryClient.invalidateQueries({ queryKey: ['deal-properties', dealId] });
        },
    });

    if (isLoading) return <div className="p-4 text-center">Cargando propiedades...</div>;

    return (
        <div className="space-y-4">
            <div className="flex justify-between items-center">
                <h3 className="text-sm font-medium text-muted-foreground">
                    Propiedades de Interés ({interests.length})
                </h3>

                <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
                    <DialogTrigger asChild>
                        <Button size="sm" variant="outline">
                            <Home className="h-4 w-4 mr-2" />
                            Vincular Propiedad
                        </Button>
                    </DialogTrigger>
                    <DialogContent>
                        <DialogHeader>
                            <DialogTitle>Vincular Propiedad</DialogTitle>
                        </DialogHeader>
                        <PropertySelector
                            onSelect={(pid) => linkMutation.mutate(pid)}
                            isLoading={linkMutation.isPending}
                        />
                    </DialogContent>
                </Dialog>
            </div>

            <div className="space-y-3">
                {interests.length === 0 ? (
                    <div className="text-center py-8 border rounded-lg border-dashed bg-gray-50">
                        <Home className="h-8 w-8 mx-auto text-gray-300 mb-2" />
                        <p className="text-sm text-muted-foreground">
                            Este lead no tiene propiedades vinculadas
                        </p>
                    </div>
                ) : (
                    interests.map((item: any) => {
                        const StatusIcon = interestLevels[item.status as keyof typeof interestLevels]?.icon || HelpCircle;

                        return (
                            <div key={item.id} className="flex gap-4 p-4 border rounded-lg bg-card hover:shadow-sm transition-shadow">
                                {/* Image */}
                                <div className="h-20 w-20 shrink-0 bg-gray-100 rounded-md overflow-hidden">
                                    {item.primary_image ? (
                                        <img
                                            src={item.primary_image}
                                            alt={item.title}
                                            className="h-full w-full object-cover"
                                        />
                                    ) : (
                                        <div className="h-full w-full flex items-center justify-center">
                                            <Home className="h-8 w-8 text-gray-300" />
                                        </div>
                                    )}
                                </div>

                                {/* Content */}
                                <div className="flex-1 min-w-0">
                                    <div className="flex justify-between items-start">
                                        <div>
                                            <h4 className="font-medium line-clamp-1 hover:text-primary cursor-pointer">
                                                {item.title}
                                            </h4>
                                            <p className="text-sm text-muted-foreground mb-2">
                                                {item.city} • {new Intl.NumberFormat('es-MX', {
                                                    style: 'currency',
                                                    currency: item.currency,
                                                    maximumFractionDigits: 0
                                                }).format(item.price)}
                                            </p>
                                        </div>
                                        <Button
                                            variant="ghost"
                                            size="icon"
                                            className="h-6 w-6 text-muted-foreground hover:text-destructive"
                                            onClick={() => {
                                                if (confirm('¿Desvincular propiedad?')) unlinkMutation.mutate(item.id);
                                            }}
                                        >
                                            <Trash2 className="h-4 w-4" />
                                        </Button>
                                    </div>

                                    {/* Actions / Status */}
                                    <div className="flex items-center gap-3">
                                        <Select
                                            value={item.status}
                                            onValueChange={(val) => updateStatusMutation.mutate({
                                                interestId: item.id,
                                                status: val
                                            })}
                                        >
                                            <SelectTrigger className="h-8 w-[180px] text-xs">
                                                <div className="flex items-center gap-2">
                                                    <StatusIcon className="h-3 w-3" />
                                                    <SelectValue />
                                                </div>
                                            </SelectTrigger>
                                            <SelectContent>
                                                {Object.entries(interestLevels).map(([key, config]) => (
                                                    <SelectItem key={key} value={key}>
                                                        <div className="flex items-center gap-2">
                                                            <config.icon className="h-3 w-3" />
                                                            {config.label}
                                                        </div>
                                                    </SelectItem>
                                                ))}
                                            </SelectContent>
                                        </Select>

                                        <Button variant="ghost" size="sm" className="h-8 text-xs" asChild>
                                            <a href={`/properties?id=${item.property_id}`} target="_blank" rel="noreferrer">
                                                <ExternalLink className="h-3 w-3 mr-1" />
                                                Ver Detalles
                                            </a>
                                        </Button>
                                    </div>
                                </div>
                            </div>
                        );
                    })
                )}
            </div>
        </div>
    );
}
