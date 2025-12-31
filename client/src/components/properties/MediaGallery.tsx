import { useState, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useToast } from '@/hooks/use-toast';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import {
    Dialog,
    DialogContent,
    DialogHeader,
    DialogTitle,
} from '@/components/ui/dialog';
import {
    Star,
    Trash2,
    Image as ImageIcon,
    Video,
    FileText,
    ChevronLeft,
    ChevronRight,
    X,
    GripVertical,
} from 'lucide-react';
import { DragDropContext, Droppable, Draggable, DropResult } from '@hello-pangea/dnd';

interface Media {
    id: number;
    media_type: string;
    file_url: string;
    file_name: string;
    file_size: number;
    is_primary: boolean;
    is_flyer: boolean;
    order_num: number;
    created_at: string;
}

interface MediaGalleryProps {
    propertyId: number;
    onRefresh?: () => void;
}

export default function MediaGallery({ propertyId, onRefresh }: MediaGalleryProps) {
    const { toast } = useToast();
    const queryClient = useQueryClient();
    const [lightboxIndex, setLightboxIndex] = useState<number | null>(null);
    const [orderedImages, setOrderedImages] = useState<Media[]>([]);

    const { data: media = [], refetch } = useQuery<Media[]>({
        queryKey: ['property-media', propertyId],
        queryFn: async () => {
            const res = await fetch(`/api/properties/${propertyId}/media`);
            if (!res.ok) throw new Error('Failed to fetch media');
            return res.json();
        },
    });

    // Sync orderedImages with media when media changes
    useEffect(() => {
        if (media && media.length > 0) {
            const imgs = media.filter(m => m.media_type === 'image' || m.media_type === 'flyer');
            setOrderedImages(imgs);
        }
    }, [media]);

    const setPrimaryMutation = useMutation({
        mutationFn: async (mediaId: number) => {
            const res = await fetch(`/api/property-media/${mediaId}`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ is_primary: true }),
            });
            if (!res.ok) throw new Error('Failed to set primary');
            return res.json();
        },
        onSuccess: (data, variables) => {
            // Optimistic-like update: manually update cache to show visual change immediately
            queryClient.setQueryData(['property-media', propertyId], (oldData: Media[] | undefined) => {
                if (!oldData) return [];
                return oldData.map(item => ({
                    ...item,
                    is_primary: item.id === variables
                }));
            });

            // Invalidate properties list to reflect the new thumbnail
            queryClient.invalidateQueries({ queryKey: ['properties'] });
            // Invalidate single property detail if it exists
            queryClient.invalidateQueries({ queryKey: ['property', propertyId] });

            toast({ title: 'Imagen principal actualizada' });
            refetch(); // Fetch source of truth
            onRefresh?.();
        },
    });

    const deleteMutation = useMutation({
        mutationFn: async (mediaId: number) => {
            const res = await fetch(`/api/property-media/${mediaId}`, {
                method: 'DELETE',
            });
            if (!res.ok) throw new Error('Failed to delete');
            return res.json();
        },
        onSuccess: () => {
            toast({ title: 'Archivo eliminado' });
            refetch();
            onRefresh?.();
        },
    });

    const handleDelete = (mediaId: number) => {
        if (confirm('¿Eliminar este archivo?')) {
            deleteMutation.mutate(mediaId);
        }
    };

    const reorderMutation = useMutation({
        mutationFn: async (mediaIds: number[]) => {
            const res = await fetch(`/api/properties/${propertyId}/media/reorder`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ media_ids: mediaIds }),
            });
            if (!res.ok) throw new Error('Failed to reorder');
            return res.json();
        },
        onSuccess: () => {
            // Invalidate to ensure consistency
            queryClient.invalidateQueries({ queryKey: ['property-media', propertyId] });
        }
    });

    useEffect(() => {
        if (media) {
            const imgs = media.filter(m => m.media_type === 'image' || m.media_type === 'flyer');
            setOrderedImages(imgs);
        }
    }, [media]);

    const handleDragEnd = (result: DropResult) => {
        if (!result.destination) return;

        const items = Array.from(orderedImages);
        const [reorderedItem] = items.splice(result.source.index, 1);
        items.splice(result.destination.index, 0, reorderedItem);

        setOrderedImages(items);

        // API Call to reorder
        const ids = items.map(i => i.id);
        reorderMutation.mutate(ids);

        // If moved to first position, set as primary
        if (result.destination.index === 0 && !reorderedItem.is_primary) {
            setPrimaryMutation.mutate(reorderedItem.id);
        }
    };

    // Use orderedImages as the source for display since it handles DnD state
    const images = orderedImages.length > 0 ? orderedImages : media.filter(m => m.media_type === 'image' || m.media_type === 'flyer');
    const videos = media.filter(m => m.media_type === 'video');
    const documents = media.filter(m => m.media_type === 'document');

    const openLightbox = (index: number) => {
        setLightboxIndex(index);
    };

    const closeLightbox = () => {
        setLightboxIndex(null);
    };

    const nextImage = () => {
        if (lightboxIndex !== null && lightboxIndex < images.length - 1) {
            setLightboxIndex(lightboxIndex + 1);
        }
    };

    const prevImage = () => {
        if (lightboxIndex !== null && lightboxIndex > 0) {
            setLightboxIndex(lightboxIndex - 1);
        }
    };

    if (media.length === 0) {
        return (
            <div className="text-center py-12 text-muted-foreground">
                <ImageIcon className="h-16 w-16 mx-auto mb-4 opacity-50" />
                <p>No hay archivos multimedia</p>
            </div>
        );
    }

    return (
        <div className="space-y-6">
            {/* Images */}
            {images.length > 0 && (
                <div>
                    <h4 className="font-medium mb-3 flex items-center gap-2">
                        <ImageIcon className="h-4 w-4" />
                        Imágenes ({images.length})
                    </h4>
                    <DragDropContext onDragEnd={handleDragEnd}>
                        <Droppable droppableId="images" direction="horizontal">
                            {(provided) => (
                                <div
                                    className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4"
                                    {...provided.droppableProps}
                                    ref={provided.innerRef}
                                >
                                    {orderedImages.map((item, index) => (
                                        <Draggable key={item.id} draggableId={item.id.toString()} index={index}>
                                            {(provided, snapshot) => (
                                                <div
                                                    ref={provided.innerRef}
                                                    {...provided.draggableProps}
                                                    {...provided.dragHandleProps}
                                                    style={{ ...provided.draggableProps.style }}
                                                    className={`relative outline-none ${snapshot.isDragging ? 'z-50' : ''}`}
                                                >
                                                    {/* Inner Visual Container for Drag Effects (Tilt, Shadow) */}
                                                    <div
                                                        className={`relative group bg-white rounded-lg transition-shadow duration-200 ${snapshot.isDragging
                                                            ? 'shadow-2xl ring-2 ring-primary z-50'
                                                            : 'hover:shadow-md'
                                                            }`}
                                                    >
                                                        <div
                                                            className="aspect-square bg-gray-100 rounded-lg overflow-hidden cursor-pointer"
                                                            onClick={() => !snapshot.isDragging && openLightbox(index)}
                                                        >
                                                            <img
                                                                src={item.file_url}
                                                                alt={item.file_name}
                                                                draggable={false}
                                                                className="w-full h-full object-cover"
                                                            />
                                                        </div>

                                                        {/* Badges */}
                                                        <div className="absolute top-2 left-2 flex gap-1 z-10">
                                                            {item.is_primary && (
                                                                <Badge className="bg-yellow-500">
                                                                    <Star className="h-3 w-3 mr-1" />
                                                                    Principal
                                                                </Badge>
                                                            )}
                                                            {item.is_flyer && (
                                                                <Badge variant="secondary">Flyer</Badge>
                                                            )}
                                                            {/* Drag Handle Icon - Visual Only */}
                                                            <div
                                                                className={`bg-black/30 text-white p-0.5 rounded transition-opacity ${snapshot.isDragging ? 'opacity-100' : 'opacity-0 group-hover:opacity-100'}`}
                                                            >
                                                                <GripVertical className="h-4 w-4" />
                                                            </div>
                                                        </div>

                                                        {/* Actions */}
                                                        <div className={`absolute top-2 right-2 transition-opacity flex gap-1 z-10 ${item.is_primary || snapshot.isDragging ? 'opacity-100' : 'opacity-0 group-hover:opacity-100'}`}>
                                                            <Button
                                                                size="icon"
                                                                variant={item.is_primary ? "secondary" : "secondary"}
                                                                className={`h-8 w-8 transition-colors ${item.is_primary ? 'bg-white/90 text-yellow-500 hover:bg-white' : 'bg-white/70 hover:bg-white hover:text-yellow-500'}`}
                                                                onClick={(e) => {
                                                                    e.stopPropagation();
                                                                    if (!item.is_primary) {
                                                                        setPrimaryMutation.mutate(item.id);
                                                                    }
                                                                }}
                                                                title={item.is_primary ? "Imagen principal" : "Establecer como principal"}
                                                            >
                                                                <Star
                                                                    className={`h-4 w-4 ${item.is_primary ? 'fill-yellow-500' : ''}`}
                                                                />
                                                            </Button>
                                                            <Button
                                                                size="icon"
                                                                variant="destructive"
                                                                className="h-8 w-8"
                                                                onClick={(e) => {
                                                                    e.stopPropagation();
                                                                    handleDelete(item.id);
                                                                }}
                                                            >
                                                                <Trash2 className="h-4 w-4" />
                                                            </Button>
                                                        </div>
                                                    </div>
                                                </div>
                                            )}
                                        </Draggable>
                                    ))}
                                    {provided.placeholder}
                                </div>
                            )}
                        </Droppable>
                    </DragDropContext>
                </div>
            )}

            {/* Videos */}
            {videos.length > 0 && (
                <div>
                    <h4 className="font-medium mb-3 flex items-center gap-2">
                        <Video className="h-4 w-4" />
                        Videos ({videos.length})
                    </h4>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        {videos.map(item => (
                            <div key={item.id} className="relative group">
                                <video
                                    src={item.file_url}
                                    controls
                                    className="w-full rounded-lg"
                                />
                                <Button
                                    size="icon"
                                    variant="destructive"
                                    className="absolute top-2 right-2 opacity-0 group-hover:opacity-100 transition-opacity"
                                    onClick={() => handleDelete(item.id)}
                                >
                                    <Trash2 className="h-4 w-4" />
                                </Button>
                            </div>
                        ))}
                    </div>
                </div>
            )}

            {/* Documents */}
            {documents.length > 0 && (
                <div>
                    <h4 className="font-medium mb-3 flex items-center gap-2">
                        <FileText className="h-4 w-4" />
                        Documentos ({documents.length})
                    </h4>
                    <div className="space-y-2">
                        {documents.map(item => (
                            <div
                                key={item.id}
                                className="flex items-center gap-3 p-3 border rounded-lg"
                            >
                                <FileText className="h-8 w-8 text-gray-500" />
                                <div className="flex-1">
                                    <p className="font-medium">{item.file_name}</p>
                                    <p className="text-sm text-muted-foreground">
                                        {(item.file_size / 1024).toFixed(1)} KB
                                    </p>
                                </div>
                                <Button
                                    variant="outline"
                                    size="sm"
                                    onClick={() => window.open(item.file_url, '_blank')}
                                >
                                    Ver
                                </Button>
                                <Button
                                    variant="destructive"
                                    size="icon"
                                    onClick={() => handleDelete(item.id)}
                                >
                                    <Trash2 className="h-4 w-4" />
                                </Button>
                            </div>
                        ))}
                    </div>
                </div>
            )}

            {/* Lightbox */}
            {lightboxIndex !== null && (
                <Dialog open onOpenChange={closeLightbox}>
                    <DialogContent className="max-w-4xl">
                        <DialogHeader>
                            <DialogTitle>
                                {images[lightboxIndex]?.file_name}
                            </DialogTitle>
                        </DialogHeader>
                        <div className="relative">
                            <img
                                src={images[lightboxIndex]?.file_url}
                                alt={images[lightboxIndex]?.file_name}
                                className="w-full h-auto max-h-[70vh] object-contain"
                            />

                            {/* Navigation */}
                            {lightboxIndex > 0 && (
                                <Button
                                    variant="secondary"
                                    size="icon"
                                    className="absolute left-2 top-1/2 -translate-y-1/2"
                                    onClick={prevImage}
                                >
                                    <ChevronLeft className="h-6 w-6" />
                                </Button>
                            )}
                            {lightboxIndex < images.length - 1 && (
                                <Button
                                    variant="secondary"
                                    size="icon"
                                    className="absolute right-2 top-1/2 -translate-y-1/2"
                                    onClick={nextImage}
                                >
                                    <ChevronRight className="h-6 w-6" />
                                </Button>
                            )}
                        </div>
                        <p className="text-center text-sm text-muted-foreground">
                            {lightboxIndex + 1} / {images.length}
                        </p>
                    </DialogContent>
                </Dialog>
            )}
        </div>
    );
}
