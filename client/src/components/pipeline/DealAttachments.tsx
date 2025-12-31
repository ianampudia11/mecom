import { useState, useRef } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { apiRequest } from '@/lib/queryClient';
import { useToast } from '@/hooks/use-toast';
import { useAuth } from '@/hooks/use-auth';
import { Button } from '@/components/ui/button';
import {
    Paperclip,
    Upload,
    Trash2,
    Download,
    FileText,
    Image as ImageIcon,
    File,
    X
} from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';
import {
    AlertDialog,
    AlertDialogAction,
    AlertDialogCancel,
    AlertDialogContent,
    AlertDialogDescription,
    AlertDialogFooter,
    AlertDialogHeader,
    AlertDialogTitle,
} from '@/components/ui/alert-dialog';
import { Dialog, DialogContent } from '@/components/ui/dialog';

interface Attachment {
    id: number;
    dealId: number;
    uploadedBy: number;
    filename: string;
    fileUrl: string;
    fileSize: number;
    mimeType: string;
    createdAt: string;
    username: string;
    uploaderName: string;
}

interface DealAttachmentsProps {
    dealId: number;
}

export default function DealAttachments({ dealId }: DealAttachmentsProps) {
    const { toast } = useToast();
    const { user } = useAuth();
    const queryClient = useQueryClient();
    const fileInputRef = useRef<HTMLInputElement>(null);
    const [attachmentToDelete, setAttachmentToDelete] = useState<number | null>(null);
    const [previewImage, setPreviewImage] = useState<string | null>(null);
    const [isDragging, setIsDragging] = useState(false);

    // Fetch attachments
    const { data: attachments = [], isLoading } = useQuery<Attachment[]>({
        queryKey: [`/api/deals/${dealId}/attachments`],
        queryFn: async () => {
            const res = await apiRequest('GET', `/api/deals/${dealId}/attachments`);
            if (!res.ok) throw new Error('Failed to fetch attachments');
            return res.json();
        },
    });

    // Upload attachment mutation
    const uploadMutation = useMutation({
        mutationFn: async (file: File) => {
            const formData = new FormData();
            formData.append('file', file);

            const res = await fetch(`/api/deals/${dealId}/attachments`, {
                method: 'POST',
                credentials: 'include',
                body: formData,
            });

            if (!res.ok) {
                const error = await res.json();
                throw new Error(error.error || 'Failed to upload file');
            }

            return res.json();
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: [`/api/deals/${dealId}/attachments`] });
            toast({
                title: 'Archivo subido',
                description: 'El archivo ha sido adjuntado exitosamente.',
            });
        },
        onError: (error: Error) => {
            toast({
                title: 'Error al subir archivo',
                description: error.message,
                variant: 'destructive',
            });
        },
    });

    // Delete attachment mutation
    const deleteMutation = useMutation({
        mutationFn: async (attachmentId: number) => {
            const res = await apiRequest('DELETE', `/api/attachments/${attachmentId}`);
            if (!res.ok) throw new Error('Failed to delete attachment');
            return res.json();
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: [`/api/deals/${dealId}/attachments`] });
            setAttachmentToDelete(null);
            toast({
                title: 'Archivo eliminado',
                description: 'El archivo ha sido eliminado.',
            });
        },
    });

    const handleFileSelect = (files: FileList | null) => {
        if (!files || files.length === 0) return;

        const file = files[0];

        // Check file size (10MB limit)
        if (file.size > 10 * 1024 * 1024) {
            toast({
                title: 'Archivo muy grande',
                description: 'El tamaño máximo permitido es 10MB.',
                variant: 'destructive',
            });
            return;
        }

        uploadMutation.mutate(file);
        if (fileInputRef.current) {
            fileInputRef.current.value = '';
        }
    };

    const handleDrop = (e: React.DragEvent) => {
        e.preventDefault();
        setIsDragging(false);
        handleFileSelect(e.dataTransfer.files);
    };

    const handleDragOver = (e: React.DragEvent) => {
        e.preventDefault();
        setIsDragging(true);
    };

    const handleDragLeave = () => {
        setIsDragging(false);
    };

    const formatFileSize = (bytes: number) => {
        if (bytes < 1024) return bytes + ' B';
        if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
        return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
    };

    const getFileIcon = (mimeType: string) => {
        if (mimeType.startsWith('image/')) return ImageIcon;
        if (mimeType.startsWith('text/') || mimeType.includes('pdf')) return FileText;
        return File;
    };

    const isImage = (mimeType: string) => mimeType.startsWith('image/');

    const canDeleteAttachment = (attachment: Attachment) => {
        if (!user || user.id === undefined) return false;
        return user.id === attachment.uploadedBy;
    };

    if (isLoading) {
        return <div className="text-sm text-gray-500">Cargando archivos adjuntos...</div>;
    }

    return (
        <div className="space-y-4">
            {/* Upload Area */}
            <div
                onDrop={handleDrop}
                onDragOver={handleDragOver}
                onDragLeave={handleDragLeave}
                className={`border-2 border-dashed rounded-lg p-6 text-center transition-colors ${isDragging
                    ? 'border-blue-500 bg-blue-50'
                    : 'border-gray-300 hover:border-gray-400'
                    }`}
            >
                <input
                    ref={fileInputRef}
                    type="file"
                    onChange={(e) => handleFileSelect(e.target.files)}
                    className="hidden"
                    accept="image/*,.pdf,.doc,.docx,.xls,.xlsx,.txt"
                />
                <Upload className="h-10 w-10 text-gray-400 mx-auto mb-3" />
                <p className="text-sm font-medium text-gray-700 mb-1">
                    Arrastra archivos aquí o{' '}
                    <button
                        onClick={() => fileInputRef.current?.click()}
                        className="text-blue-600 hover:text-blue-700 underline"
                        disabled={uploadMutation.isPending}
                    >
                        selecciona
                    </button>
                </p>
                <p className="text-xs text-gray-500">
                    Máximo 10MB por archivo
                </p>
            </div>

            {/* Attachments List */}
            {attachments.length > 0 ? (
                <div className="grid grid-cols-1 gap-3">
                    {attachments.map((attachment) => {
                        const FileIcon = getFileIcon(attachment.mimeType);
                        const isImg = isImage(attachment.mimeType);

                        return (
                            <div
                                key={attachment.id}
                                className="group border rounded-lg p-3 hover:bg-gray-50 transition-colors"
                            >
                                <div className="flex items-start gap-3">
                                    {/* File Icon or Thumbnail */}
                                    {isImg ? (
                                        <div
                                            onClick={() => setPreviewImage(attachment.fileUrl)}
                                            className="h-12 w-12 rounded border overflow-hidden flex-shrink-0 cursor-pointer hover:opacity-80"
                                        >
                                            <img
                                                src={attachment.fileUrl}
                                                alt={attachment.filename}
                                                className="h-full w-full object-cover"
                                            />
                                        </div>
                                    ) : (
                                        <div className="h-12 w-12 rounded border flex items-center justify-center bg-gray-100 flex-shrink-0">
                                            <FileIcon className="h-6 w-6 text-gray-600" />
                                        </div>
                                    )}

                                    {/* File Info */}
                                    <div className="flex-1 min-w-0">
                                        <p className="text-sm font-medium text-gray-900 truncate">
                                            {attachment.filename}
                                        </p>
                                        <p className="text-xs text-gray-500">
                                            {formatFileSize(attachment.fileSize)} • {' '}
                                            {attachment.uploaderName || attachment.username} • {' '}
                                            {formatDistanceToNow(new Date(attachment.createdAt), { addSuffix: true })}
                                        </p>
                                    </div>

                                    {/* Actions */}
                                    <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                                        <Button
                                            size="sm"
                                            variant="ghost"
                                            onClick={() => window.open(attachment.fileUrl, '_blank')}
                                            className="h-8 w-8 p-0"
                                            title="Descargar"
                                        >
                                            <Download className="h-4 w-4" />
                                        </Button>
                                        {canDeleteAttachment(attachment) && (
                                            <Button
                                                size="sm"
                                                variant="ghost"
                                                onClick={() => setAttachmentToDelete(attachment.id)}
                                                className="h-8 w-8 p-0 text-red-600 hover:text-red-700"
                                                title="Eliminar"
                                            >
                                                <Trash2 className="h-4 w-4" />
                                            </Button>
                                        )}
                                    </div>
                                </div>
                            </div>
                        );
                    })}
                </div>
            ) : (
                <div className="text-center py-8 border-2 border-dashed rounded-lg">
                    <Paperclip className="h-12 w-12 text-gray-400 mx-auto mb-2" />
                    <p className="text-sm text-gray-500">
                        No hay archivos adjuntos aún
                    </p>
                </div>
            )}

            {/* Image Preview Dialog */}
            <Dialog open={previewImage !== null} onOpenChange={() => setPreviewImage(null)}>
                <DialogContent className="max-w-4xl">
                    {previewImage && (
                        <div className="relative">
                            <Button
                                onClick={() => setPreviewImage(null)}
                                className="absolute top-2 right-2 z-10"
                                size="sm"
                                variant="secondary"
                            >
                                <X className="h-4 w-4" />
                            </Button>
                            <img
                                src={previewImage}
                                alt="Preview"
                                className="w-full h-auto max-h-[80vh] object-contain"
                            />
                        </div>
                    )}
                </DialogContent>
            </Dialog>

            {/* Delete Confirmation Dialog */}
            <AlertDialog
                open={attachmentToDelete !== null}
                onOpenChange={() => setAttachmentToDelete(null)}
            >
                <AlertDialogContent>
                    <AlertDialogHeader>
                        <AlertDialogTitle>¿Eliminar archivo?</AlertDialogTitle>
                        <AlertDialogDescription>
                            Esta acción no se puede deshacer. El archivo será eliminado permanentemente.
                        </AlertDialogDescription>
                    </AlertDialogHeader>
                    <AlertDialogFooter>
                        <AlertDialogCancel>Cancelar</AlertDialogCancel>
                        <AlertDialogAction
                            onClick={() => attachmentToDelete && deleteMutation.mutate(attachmentToDelete)}
                            className="bg-red-600 hover:bg-red-700"
                        >
                            Eliminar
                        </AlertDialogAction>
                    </AlertDialogFooter>
                </AlertDialogContent>
            </AlertDialog>
        </div>
    );
}
