import { useState, useEffect } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Search, Loader2, Home, MapPin, Plus } from 'lucide-react';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { ScrollArea } from '@/components/ui/scroll-area';
import { cn } from '@/lib/utils';
import { useDebounce } from '@/hooks/use-debounce';

interface Property {
    id: number;
    title: string;
    price: number;
    currency: string;
    city: string;
    primary_image?: string;
    status: string;
}

interface PropertySelectorProps {
    onSelect: (propertyId: number) => void;
    isLoading?: boolean;
}

export default function PropertySelector({ onSelect, isLoading }: PropertySelectorProps) {
    const [searchTerm, setSearchTerm] = useState('');
    const debouncedSearch = useDebounce(searchTerm, 500);

    const { data: properties = [], isFetching } = useQuery<Property[]>({
        queryKey: ['properties-search', debouncedSearch],
        queryFn: async () => {
            const params = new URLSearchParams();
            if (debouncedSearch) params.append('search', debouncedSearch);
            params.append('status', 'available');
            params.append('limit', '10');

            const res = await fetch(`/api/properties?${params.toString()}`);
            if (!res.ok) throw new Error('Failed to search properties');
            return res.json();
        },
        enabled: true // Always fetch initial list
    });

    return (
        <div className="space-y-4">
            <div className="relative">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                <Input
                    placeholder="Buscar propiedad por nombre, ciudad o código..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="pl-9"
                />
            </div>

            <ScrollArea className="h-[300px] border rounded-md p-2">
                {isFetching && properties.length === 0 ? (
                    <div className="flex items-center justify-center py-8 text-muted-foreground">
                        <Loader2 className="h-6 w-6 animate-spin mr-2" />
                        Buscando...
                    </div>
                ) : properties.length === 0 ? (
                    <div className="text-center py-8 text-muted-foreground">
                        No se encontraron propiedades disponibles
                    </div>
                ) : (
                    <div className="space-y-2">
                        {properties.map((property) => (
                            <div
                                key={property.id}
                                className="flex items-start gap-3 p-3 rounded-lg border hover:bg-muted/50 transition-colors"
                            >
                                {/* Image Thumbnail */}
                                <div className="h-16 w-16 bg-gray-100 rounded-md overflow-hidden shrink-0">
                                    {property.primary_image ? (
                                        <img
                                            src={property.primary_image}
                                            alt={property.title}
                                            className="h-full w-full object-cover"
                                        />
                                    ) : (
                                        <div className="h-full w-full flex items-center justify-center">
                                            <Home className="h-6 w-6 text-gray-300" />
                                        </div>
                                    )}
                                </div>

                                {/* Info */}
                                <div className="flex-1 min-w-0">
                                    <h4 className="font-medium text-sm line-clamp-1">{property.title}</h4>
                                    <div className="flex items-center gap-1 text-xs text-muted-foreground mt-1">
                                        <MapPin className="h-3 w-3" />
                                        {property.city}
                                    </div>
                                    <div className="mt-1 font-semibold text-sm">
                                        {new Intl.NumberFormat('es-MX', {
                                            style: 'currency',
                                            currency: property.currency,
                                            maximumFractionDigits: 0
                                        }).format(property.price)}
                                    </div>
                                </div>

                                {/* Action */}
                                <Button
                                    size="sm"
                                    variant="secondary"
                                    onClick={() => onSelect(property.id)}
                                    disabled={isLoading}
                                >
                                    <Plus className="h-4 w-4 mr-1" />
                                    Vincular
                                </Button>
                            </div>
                        ))}
                    </div>
                )}
            </ScrollArea>
        </div>
    );
}
