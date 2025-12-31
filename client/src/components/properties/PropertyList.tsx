import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Plus, Search, Filter, Home, Building, MapPin } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import PropertyCard from '@/components/properties/PropertyCard';
import PropertyForm from '@/components/properties/PropertyForm';
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
} from '@/components/ui/dialog';

interface Property {
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
}

export default function PropertyList() {
    const [searchQuery, setSearchQuery] = useState('');
    const [statusFilter, setStatusFilter] = useState('all');
    const [typeFilter, setTypeFilter] = useState('all');
    const [showForm, setShowForm] = useState(false);
    const [selectedProperty, setSelectedProperty] = useState<Property | null>(null);

    const { data: properties = [], isLoading, refetch } = useQuery<Property[]>({
        queryKey: ['properties', searchQuery, statusFilter, typeFilter],
        queryFn: async () => {
            const params = new URLSearchParams();
            if (searchQuery) params.append('search', searchQuery);
            if (statusFilter !== 'all') params.append('status', statusFilter);
            if (typeFilter !== 'all') params.append('type', typeFilter);

            const res = await fetch(`/api/properties?${params.toString()}`);
            if (!res.ok) throw new Error('Failed to fetch properties');
            return res.json();
        },
    });

    const { data: stats } = useQuery({
        queryKey: ['properties-stats'],
        queryFn: async () => {
            const res = await fetch('/api/properties/stats');
            if (!res.ok) throw new Error('Failed to fetch stats');
            return res.json();
        },
    });

    const handleCreate = () => {
        setSelectedProperty(null);
        setShowForm(true);
    };

    const handleEdit = (property: Property) => {
        setSelectedProperty(property);
        setShowForm(true);
    };

    const handleFormClose = () => {
        setShowForm(false);
        setSelectedProperty(null);
        refetch();
    };

    return (
        <div className="space-y-6">
            {/* Header & Actions */}
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                <div>
                    <h1 className="text-2xl font-bold flex items-center gap-2">
                        <Building className="h-6 w-6" />
                        Propiedades
                    </h1>
                    <p className="text-sm text-muted-foreground mt-1">
                        Gestiona tu catálogo de propiedades
                    </p>
                </div>

                <div className="flex flex-col sm:flex-row gap-3">
                    <div className="relative">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                        <Input
                            placeholder="Buscar..."
                            value={searchQuery}
                            onChange={(e) => setSearchQuery(e.target.value)}
                            className="pl-9 w-full sm:w-[250px]"
                        />
                    </div>

                    <Select value={statusFilter} onValueChange={setStatusFilter}>
                        <SelectTrigger className="w-full sm:w-[150px]">
                            <SelectValue placeholder="Estado" />
                        </SelectTrigger>
                        <SelectContent>
                            <SelectItem value="all">Todos los estados</SelectItem>
                            <SelectItem value="available">Disponible</SelectItem>
                            <SelectItem value="reserved">Reservada</SelectItem>
                            <SelectItem value="sold">Vendida</SelectItem>
                            <SelectItem value="rented">Rentada</SelectItem>
                            <SelectItem value="inactive">Inactiva</SelectItem>
                        </SelectContent>
                    </Select>

                    <Select value={typeFilter} onValueChange={setTypeFilter}>
                        <SelectTrigger className="w-full sm:w-[150px]">
                            <SelectValue placeholder="Tipo" />
                        </SelectTrigger>
                        <SelectContent>
                            <SelectItem value="all">Todos los tipos</SelectItem>
                            <SelectItem value="house">Casa</SelectItem>
                            <SelectItem value="apartment">Apartamento</SelectItem>
                            <SelectItem value="land">Terreno</SelectItem>
                            <SelectItem value="commercial">Comercial</SelectItem>
                            <SelectItem value="office">Oficina</SelectItem>
                            <SelectItem value="warehouse">Bodega</SelectItem>
                        </SelectContent>
                    </Select>

                    <Button onClick={handleCreate}>
                        <Plus className="h-4 w-4 mr-2" />
                        Nueva
                    </Button>
                </div>
            </div>

            {/* Stats */}
            {stats && (
                <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
                    <div className="bg-blue-50/50 border border-blue-100 rounded-lg p-3">
                        <p className="text-xs text-blue-600 font-medium">Total</p>
                        <p className="text-2xl font-bold text-blue-700">{stats.total || 0}</p>
                    </div>
                    <div className="bg-green-50/50 border border-green-100 rounded-lg p-3">
                        <p className="text-xs text-green-600 font-medium">Disponibles</p>
                        <p className="text-2xl font-bold text-green-700">{stats.available || 0}</p>
                    </div>
                    <div className="bg-yellow-50/50 border border-yellow-100 rounded-lg p-3">
                        <p className="text-xs text-yellow-600 font-medium">Reservadas</p>
                        <p className="text-2xl font-bold text-yellow-700">{stats.reserved || 0}</p>
                    </div>
                    <div className="bg-purple-50/50 border border-purple-100 rounded-lg p-3">
                        <p className="text-xs text-purple-600 font-medium">Vendidas</p>
                        <p className="text-2xl font-bold text-purple-700">{stats.sold || 0}</p>
                    </div>
                    <div className="bg-gray-50/50 border border-gray-100 rounded-lg p-3">
                        <p className="text-xs text-gray-600 font-medium">Promedio</p>
                        <p className="text-xl font-bold text-gray-700 truncate">
                            ${Math.round(stats.avg_price || 0).toLocaleString()}
                        </p>
                    </div>
                </div>
            )}

            {/* Property Grid */}
            <div className="min-h-[200px]">
                {isLoading ? (
                    <div className="flex items-center justify-center p-12">
                        <div className="text-center">
                            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mx-auto mb-4"></div>
                            <p className="text-muted-foreground text-sm">Cargando propiedades...</p>
                        </div>
                    </div>
                ) : properties.length === 0 ? (
                    <div className="border-2 border-dashed rounded-lg p-12 flex flex-col items-center justify-center text-center">
                        <Home className="h-12 w-12 text-muted-foreground/50 mb-4" />
                        <h3 className="text-lg font-medium mb-1">No hay propiedades</h3>
                        <p className="text-muted-foreground text-sm mb-4">
                            Comienza agregando tu primera propiedad
                        </p>
                        <Button variant="outline" onClick={handleCreate}>
                            Agregar Propiedad
                        </Button>
                    </div>
                ) : (
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
                        {properties.map((property) => (
                            <PropertyCard
                                key={property.id}
                                property={property}
                                onEdit={handleEdit}
                                onRefresh={refetch}
                            />
                        ))}
                    </div>
                )}
            </div>

            {/* Create/Edit Dialog */}
            <Dialog open={showForm} onOpenChange={setShowForm}>
                <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
                    <DialogHeader>
                        <DialogTitle>
                            {selectedProperty ? 'Editar Propiedad' : 'Nueva Propiedad'}
                        </DialogTitle>
                    </DialogHeader>
                    <PropertyForm
                        property={selectedProperty}
                        onClose={handleFormClose}
                    />
                </DialogContent>
            </Dialog>
        </div>
    );
}
