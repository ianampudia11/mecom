import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import {
    Card,
    CardContent,
    CardFooter,
    CardHeader,
} from '@/components/ui/card';
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import {
    Bed,
    Bath,
    Square,
    MapPin,
    MoreVertical,
    Edit,
    Trash2,
    Eye,
    Image as ImageIcon,
    Images,
} from 'lucide-react';
import { useState } from 'react';
import { useMutation } from '@tanstack/react-query';
import { useToast } from '@/hooks/use-toast';
import {
    Dialog,
    DialogContent,
    DialogHeader,
    DialogTitle,
} from '@/components/ui/dialog';
import MediaGallery from './MediaGallery';

interface PropertyCardProps {
    property: {
        id: number;
        name: string;
        type: string;
        status: string;
        price: number;
        currency: string;
        city: string;
        address: string;
        bedrooms: number;
        bathrooms: number;
        area_m2: number;
        primary_image: string;
        files?: any[];
        media_count: number;
        agent_name: string;
    };
    onEdit: (property: any) => void;
    onRefresh: () => void;
}

const statusColors = {
    available: 'bg-green-100 text-green-700 border-green-200',
    reserved: 'bg-yellow-100 text-yellow-700 border-yellow-200',
    sold: 'bg-purple-100 text-purple-700 border-purple-200',
    rented: 'bg-blue-100 text-blue-700 border-blue-200',
    pending: 'bg-orange-100 text-orange-700 border-orange-200',
    inactive: 'bg-gray-100 text-gray-700 border-gray-200',
};

const statusLabels = {
    available: 'Disponible',
    reserved: 'Reservada',
    sold: 'Vendida',
    rented: 'Rentada',
    pending: 'Pendiente',
    inactive: 'Inactiva',
};

const typeLabels = {
    house: 'Casa',
    apartment: 'Apartamento',
    land: 'Terreno',
    commercial: 'Comercial',
    office: 'Oficina',
    warehouse: 'Bodega',
    other: 'Otro',
};

export default function PropertyCard({ property, onEdit, onRefresh }: PropertyCardProps) {
    const { toast } = useToast();
    const [showGallery, setShowGallery] = useState(false);

    const deleteMutation = useMutation({
        mutationFn: async () => {
            const res = await fetch(`/api/properties/${property.id}`, {
                method: 'DELETE',
            });
            if (!res.ok) throw new Error('Failed to delete property');
            return res.json();
        },
        onSuccess: () => {
            toast({
                title: 'Propiedad eliminada',
                description: 'La propiedad ha sido eliminada exitosamente',
            });
            onRefresh();
        },
        onError: () => {
            toast({
                title: 'Error',
                description: 'No se pudo eliminar la propiedad',
                variant: 'destructive',
            });
        },
    });

    const handleDelete = () => {
        if (confirm('¿Estás seguro de eliminar esta propiedad?')) {
            deleteMutation.mutate();
        }
    };

    const formatPrice = (price: number, currency: string) => {
        return new Intl.NumberFormat('es-MX', {
            style: 'currency',
            currency: currency || 'USD',
            minimumFractionDigits: 0,
            maximumFractionDigits: 0,
        }).format(price);
    };

    return (
        <Card className="overflow-hidden hover:shadow-lg transition-shadow">
            <CardHeader className="p-0">
                {/* Image */}
                <div className="relative h-48 bg-gray-200">
                    {(() => {
                        // Try to get the first image from files array
                        const firstImage = property.files && property.files.length > 0
                            ? property.files.find((f: any) => f.type?.startsWith('image/') || f.type === 'image')
                            : null;

                        const imageUrl = property.primary_image || firstImage?.url;

                        return imageUrl ? (
                            <img
                                src={imageUrl}
                                alt={property.name}
                                className="w-full h-full object-cover"
                            />
                        ) : (
                            <div className="w-full h-full flex items-center justify-center">
                                <ImageIcon className="h-16 w-16 text-gray-400" />
                            </div>
                        );
                    })()}

                    {/* Status Badge */}
                    <div className="absolute top-2 left-2">
                        <Badge
                            className={`${statusColors[property.status as keyof typeof statusColors]} border`}
                        >
                            {statusLabels[property.status as keyof typeof statusLabels]}
                        </Badge>
                    </div>

                    {/* Media Count - Clickable to open gallery */}
                    {(property.media_count > 0 || (property.files && property.files.length > 0)) && (
                        <div
                            className="absolute bottom-2 right-2 bg-black/70 text-white px-2 py-1 rounded text-xs flex items-center gap-1 cursor-pointer hover:bg-black/90 transition-colors"
                            onClick={(e) => {
                                e.stopPropagation();
                                setShowGallery(true);
                            }}
                        >
                            <Images className="h-3 w-3" />
                            {property.media_count || property.files?.length || 0}
                        </div>
                    )}

                    {/* Actions Menu */}
                    <div className="absolute top-2 right-2">
                        <DropdownMenu>
                            <DropdownMenuTrigger asChild>
                                <Button
                                    variant="ghost"
                                    size="icon"
                                    className="h-8 w-8 bg-white/90 hover:bg-white"
                                >
                                    <MoreVertical className="h-4 w-4" />
                                </Button>
                            </DropdownMenuTrigger>
                            <DropdownMenuContent align="end">
                                <DropdownMenuItem onClick={() => onEdit(property)}>
                                    <Edit className="h-4 w-4 mr-2" />
                                    Editar
                                </DropdownMenuItem>
                                <DropdownMenuItem onClick={handleDelete} className="text-destructive">
                                    <Trash2 className="h-4 w-4 mr-2" />
                                    Eliminar
                                </DropdownMenuItem>
                            </DropdownMenuContent>
                        </DropdownMenu>
                    </div>
                </div>
            </CardHeader>

            <CardContent className="p-4">
                {/* Type */}
                <p className="text-xs text-muted-foreground uppercase tracking-wide mb-1">
                    {typeLabels[property.type as keyof typeof typeLabels]}
                </p>

                {/* Title */}
                <h3 className="font-semibold text-lg leading-tight mb-2 line-clamp-2">
                    {property.name}
                </h3>

                {/* Location */}
                {property.city && (
                    <div className="flex items-center gap-1 text-sm text-muted-foreground mb-3">
                        <MapPin className="h-3 w-3" />
                        <span className="line-clamp-1">{property.address || property.city}</span>
                    </div>
                )}

                {/* Price */}
                <p className="text-2xl font-bold text-primary mb-3">
                    {formatPrice(property.price, property.currency)}
                </p>

                {/* Features */}
                <div className="flex items-center gap-4 text-sm text-muted-foreground">
                    {property.bedrooms > 0 && (
                        <div className="flex items-center gap-1">
                            <Bed className="h-4 w-4" />
                            <span>{property.bedrooms}</span>
                        </div>
                    )}
                    {property.bathrooms > 0 && (
                        <div className="flex items-center gap-1">
                            <Bath className="h-4 w-4" />
                            <span>{property.bathrooms}</span>
                        </div>
                    )}
                    {property.area_m2 > 0 && (
                        <div className="flex items-center gap-1">
                            <Square className="h-4 w-4" />
                            <span>{property.area_m2} m²</span>
                        </div>
                    )}
                </div>
            </CardContent>

            {property.agent_name && (
                <CardFooter className="px-4 py-3 bg-gray-50 border-t">
                    <p className="text-xs text-muted-foreground">
                        Agente: <span className="font-medium text-foreground">{property.agent_name}</span>
                    </p>
                </CardFooter>
            )}

            {/* Gallery Dialog */}
            <Dialog open={showGallery} onOpenChange={setShowGallery}>
                <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
                    <DialogHeader>
                        <DialogTitle>Galería Multimedia - {property.name}</DialogTitle>
                    </DialogHeader>
                    <MediaGallery propertyId={property.id} onRefresh={onRefresh} />
                </DialogContent>
            </Dialog>
        </Card >
    );
}
