import { useState } from 'react';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { useToast } from '@/hooks/use-toast';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from '@/components/ui/select';
import { Loader2, Upload, X, FileText, Video, Image as ImageIcon, Info, Images } from 'lucide-react';
import {
    Tabs,
    TabsContent,
    TabsList,
    TabsTrigger,
} from "@/components/ui/tabs";
import MediaUploader from './MediaUploader';
import MediaGallery from './MediaGallery';

interface PropertyFormProps {
    property?: any;
    onClose: () => void;
}

export default function PropertyForm({ property, onClose }: PropertyFormProps) {
    const { toast } = useToast();
    const queryClient = useQueryClient();
    const [formData, setFormData] = useState({
        name: property?.name || property?.title || '',
        description: property?.description || '',
        status: property?.status || 'available',
        price: property?.price || '',
        currency: property?.currency || 'USD',
        negotiable: property?.negotiable ?? true,
        address: property?.address || '',
        city: property?.city || '',
        state: property?.state || '',
        country: property?.country || '',
        bedrooms: property?.bedrooms || '',
        bathrooms: property?.bathrooms || '',
        floors: property?.floors || '1',
        files: property?.files || [],
    });

    const saveMutation = useMutation({
        mutationFn: async (data: any) => {
            const url = property
                ? `/api/properties/${property.id}`
                : '/api/properties';
            const method = property ? 'PUT' : 'POST';

            const res = await fetch(url, {
                method,
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(data),
            });

            if (!res.ok) {
                const error = await res.json();
                throw new Error(error.error || 'Failed to save property');
            }

            return res.json();
        },
        onSuccess: () => {
            toast({
                title: property ? 'Propiedad actualizada' : 'Propiedad creada',
                description: 'Los cambios se guardaron exitosamente',
            });
            onClose();
        },
        onError: (error: Error) => {
            toast({
                title: 'Error',
                description: error.message,
                variant: 'destructive',
            });
        },
    });

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();

        // Convert numeric fields
        const dataToSend = {
            ...formData,
            price: formData.price ? parseFloat(formData.price) : null,
            bedrooms: formData.bedrooms ? parseInt(formData.bedrooms) : null,
            bathrooms: formData.bathrooms ? parseInt(formData.bathrooms) : null,
            floors: formData.floors ? parseInt(formData.floors) : 1,
        };

        saveMutation.mutate(dataToSend);
    };

    const [imageUrl, setImageUrl] = useState('');

    const saveUrlMediaMutation = useMutation({
        mutationFn: async (url: string) => {
            const res = await fetch(`/api/properties/${property.id}/media/url`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ url, media_type: 'image' }),
            });
            if (!res.ok) throw new Error('Failed to save URL');
            return res.json();
        },
        onSuccess: () => {
            setImageUrl('');
            toast({ title: 'Imagen agregada', description: 'La imagen por URL se ha guardado.' });
            if (property?.id) {
                queryClient.invalidateQueries({ queryKey: ['property-media', property.id] });
            }
        },
        onError: (err) => {
            toast({ title: 'Error', description: 'No se pudo guardar la URL', variant: 'destructive' });
        }
    });

    const handleAddImageUrl = () => {
        if (!imageUrl.trim()) return;
        saveUrlMediaMutation.mutate(imageUrl);
    };



    const handleChange = (field: string, value: any) => {
        setFormData((prev) => ({ ...prev, [field]: value }));
    };

    return (
        <Tabs defaultValue="info" className="w-full">
            <TabsList className="grid w-full grid-cols-2 mb-4">
                <TabsTrigger value="info" className="flex items-center gap-2">
                    <Info className="h-4 w-4" />
                    Información
                </TabsTrigger>
                <TabsTrigger value="media" className="flex items-center gap-2" disabled={!property?.id}>
                    <Images className="h-4 w-4" />
                    Multimedia
                </TabsTrigger>
            </TabsList>

            <TabsContent value="info">
                <form onSubmit={handleSubmit} className="space-y-6">
                    {/* Basic Information */}
                    <div className="space-y-4">
                        <h3 className="font-semibold text-lg">Información Básica</h3>

                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <div className="md:col-span-2">
                                <Label htmlFor="name">Título *</Label>
                                <Input
                                    id="name"
                                    value={formData.name}
                                    onChange={(e) => handleChange('name', e.target.value)}
                                    placeholder="Ej: Casa en el Centro con 3 habitaciones"
                                    required
                                />
                            </div>

                            <div className="md:col-span-2">
                                <Label htmlFor="description">Descripción</Label>
                                <Textarea
                                    id="description"
                                    value={formData.description}
                                    onChange={(e) => handleChange('description', e.target.value)}
                                    placeholder="Descripción detallada de la propiedad..."
                                    rows={3}
                                />
                            </div>
                        </div>
                    </div>

                    {/* Price */}
                    <div className="space-y-4">
                        <h3 className="font-semibold text-lg">Precio</h3>
                        <div className="grid grid-cols-2 gap-4">
                            <div>
                                <Label htmlFor="price">Precio</Label>
                                <Input
                                    id="price"
                                    type="number"
                                    step="0.01"
                                    value={formData.price}
                                    onChange={(e) => handleChange('price', e.target.value)}
                                    placeholder="150000"
                                />
                            </div>
                            <div>
                                <Label htmlFor="currency">Moneda</Label>
                                <Select
                                    value={formData.currency}
                                    onValueChange={(value) => handleChange('currency', value)}
                                >
                                    <SelectTrigger>
                                        <SelectValue />
                                    </SelectTrigger>
                                    <SelectContent>
                                        <SelectItem value="USD">USD</SelectItem>
                                        <SelectItem value="MXN">MXN</SelectItem>
                                        <SelectItem value="EUR">EUR</SelectItem>
                                    </SelectContent>
                                </Select>
                            </div>
                        </div>
                    </div>

                    {/* Original URL Input and FileList removed/condensed or kept as legacy? 
                        User wants "upgrade" so we can keep legacy for reference or remove if we trust the new system.
                        Given the request "solo se puede colocar link... ahora quiero subir", it implies REPLACING or ADDING.
                        Since we are in "Info" tab, let's keep the textual URL input as a fallback "Quick Media" or similar?
                        Better to keep it clean. I will hide the legacy media section here and focus on the Media tab.
                        Actually, let's keep the legacy section as "Enlaces externos" just in case, 
                        BUT the user complaint suggests they want a real gallery. 
                        Let's REMOVE the old "Media" section from Info tab to avoid confusion.
                     */}

                    {/* Actions */}
                    <div className="flex justify-end gap-3 pt-4 border-t">
                        <Button type="button" variant="outline" onClick={onClose}>
                            Cancelar
                        </Button>
                        <Button type="submit" disabled={saveMutation.isPending}>
                            {saveMutation.isPending && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                            {property ? 'Actualizar' : 'Crear'} Propiedad
                        </Button>
                    </div>
                </form>
            </TabsContent>

            <TabsContent value="media" className="min-h-[400px]">
                {property?.id ? (
                    <div className="space-y-6">
                        <div className="bg-blue-50 p-4 rounded-lg text-blue-800 text-sm mb-4">
                            <strong>Nota:</strong> Aquí puedes subir múltiples imágenes y videos. La primera imagen (o la marcada con estrella) será la portada.
                        </div>

                        {/* URL Input Section */}
                        <div className="flex gap-2 items-end p-4 border rounded-lg bg-gray-50">
                            <div className="flex-1 space-y-2">
                                <Label>Agregar imagen por URL</Label>
                                <Input
                                    type="url"
                                    placeholder="https://ejemplo.com/imagen.jpg"
                                    value={imageUrl}
                                    onChange={(e) => setImageUrl(e.target.value)}
                                    onKeyPress={(e) => e.key === 'Enter' && (e.preventDefault(), handleAddImageUrl())}
                                />
                            </div>
                            <Button type="button" onClick={handleAddImageUrl} disabled={!imageUrl.trim() || saveUrlMediaMutation.isPending}>
                                {saveUrlMediaMutation.isPending ? <Loader2 className="h-4 w-4 animate-spin" /> : 'Agregar Link'}
                            </Button>
                        </div>



                        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                            <div className="lg:col-span-1">
                                <h3 className="font-semibold mb-4">Subir Archivos</h3>
                                <MediaUploader propertyId={property.id} onUploadComplete={() => {
                                    queryClient.invalidateQueries({ queryKey: ['property-media', property.id] });
                                }} />
                            </div>
                            <div className="lg:col-span-2">
                                <h3 className="font-semibold mb-4">Galería</h3>
                                <MediaGallery propertyId={property.id} />
                            </div>
                        </div>
                    </div>
                ) : (
                    <div className="flex flex-col items-center justify-center h-64 text-center p-8 bg-gray-50 rounded-lg border-2 border-dashed">
                        <ImageIcon className="h-12 w-12 text-gray-300 mb-4" />
                        <h3 className="font-medium text-lg text-gray-900">Guarda la propiedad primero</h3>
                        <p className="text-gray-500 mt-2 max-w-sm">
                            Para subir imágenes y administrar la galería, primero debes completar la información básica y guardar la propiedad.
                        </p>
                    </div>
                )}
            </TabsContent>
        </Tabs>
    );
}
