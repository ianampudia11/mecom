import { useState, useCallback } from 'react';
import { useDropzone } from 'react-dropzone';
import { useMutation } from '@tanstack/react-query';
import { useToast } from '@/hooks/use-toast';
import { Button } from '@/components/ui/button';
import { Progress } from '@/components/ui/progress';
import { Upload, X, Image, Video, FileText, Loader2 } from 'lucide-react';

interface MediaUploaderProps {
    propertyId: number;
    onUploadComplete: () => void;
}

export default function MediaUploader({ propertyId, onUploadComplete }: MediaUploaderProps) {
    const { toast } = useToast();
    const [uploading, setUploading] = useState(false);
    const [uploadProgress, setUploadProgress] = useState(0);
    const [selectedFiles, setSelectedFiles] = useState<File[]>([]);

    const uploadMutation = useMutation({
        mutationFn: async (files: File[]) => {
            const formData = new FormData();
            files.forEach(file => formData.append('files', file));

            const res = await fetch(`/api/properties/${propertyId}/media`, {
                method: 'POST',
                body: formData,
            });

            if (!res.ok) {
                const error = await res.json();
                throw new Error(error.error || 'Upload failed');
            }

            return res.json();
        },
        onSuccess: () => {
            toast({
                title: 'Archivos subidos',
                description: `${selectedFiles.length} archivo(s) subidos exitosamente`,
            });
            setSelectedFiles([]);
            setUploadProgress(0);
            onUploadComplete();
        },
        onError: (error: Error) => {
            toast({
                title: 'Error al subir',
                description: error.message,
                variant: 'destructive',
            });
            setUploadProgress(0);
        },
        onMutate: () => {
            setUploading(true);
            // Simulate progress
            let progress = 0;
            const interval = setInterval(() => {
                progress += 10;
                if (progress <= 90) {
                    setUploadProgress(progress);
                } else {
                    clearInterval(interval);
                }
            }, 300);
        },
        onSettled: () => {
            setUploading(false);
            setUploadProgress(100);
            setTimeout(() => setUploadProgress(0), 1000);
        },
    });

    const onDrop = useCallback((acceptedFiles: File[]) => {
        setSelectedFiles(prev => [...prev, ...acceptedFiles]);
    }, []);

    const { getRootProps, getInputProps, isDragActive } = useDropzone({
        onDrop,
        accept: {
            'image/*': ['.jpeg', '.jpg', '.png', '.gif', '.webp'],
            'video/*': ['.mp4', '.mov', '.avi'],
            'application/pdf': ['.pdf'],
        },
        maxSize: 100 * 1024 * 1024, // 100MB
        multiple: true,
    });

    const removeFile = (index: number) => {
        setSelectedFiles(prev => prev.filter((_, i) => i !== index));
    };

    const handleUpload = () => {
        if (selectedFiles.length > 0) {
            uploadMutation.mutate(selectedFiles);
        }
    };

    const getFileIcon = (file: File) => {
        if (file.type.startsWith('image/')) return <Image className="h-8 w-8 text-blue-500" />;
        if (file.type.startsWith('video/')) return <Video className="h-8 w-8 text-purple-500" />;
        return <FileText className="h-8 w-8 text-gray-500" />;
    };

    const formatFileSize = (bytes: number) => {
        if (bytes < 1024) return bytes + ' B';
        if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
        return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
    };

    return (
        <div className="space-y-4">
            {/* Dropzone */}
            <div
                {...getRootProps()}
                className={`border-2 border-dashed rounded-lg p-8 text-center cursor-pointer transition-colors ${isDragActive
                        ? 'border-primary bg-primary/5'
                        : 'border-gray-300 hover:border-primary'
                    }`}
            >
                <input {...getInputProps()} />
                <Upload className="h-12 w-12 mx-auto mb-4 text-muted-foreground" />
                {isDragActive ? (
                    <p className="text-lg font-medium">Suelta los archivos aquí...</p>
                ) : (
                    <div>
                        <p className="text-lg font-medium mb-2">
                            Arrastra archivos aquí o haz click para seleccionar
                        </p>
                        <p className="text-sm text-muted-foreground">
                            Imágenes, videos (hasta 100MB) y PDFs
                        </p>
                    </div>
                )}
            </div>

            {/* Selected Files */}
            {selectedFiles.length > 0 && (
                <div className="space-y-3">
                    <div className="flex items-center justify-between">
                        <h4 className="font-medium">
                            Archivos seleccionados ({selectedFiles.length})
                        </h4>
                        <Button
                            onClick={handleUpload}
                            disabled={uploading}
                            size="sm"
                        >
                            {uploading && <Loader2 className="h-4 w-4 mr-2 animate-spin" />}
                            Subir Todo
                        </Button>
                    </div>

                    <div className="space-y-2 max-h-64 overflow-y-auto">
                        {selectedFiles.map((file, index) => (
                            <div
                                key={index}
                                className="flex items-center gap-3 p-3 border rounded-lg"
                            >
                                {getFileIcon(file)}
                                <div className="flex-1 min-w-0">
                                    <p className="font-medium truncate">{file.name}</p>
                                    <p className="text-sm text-muted-foreground">
                                        {formatFileSize(file.size)}
                                    </p>
                                </div>
                                <Button
                                    variant="ghost"
                                    size="icon"
                                    onClick={() => removeFile(index)}
                                    disabled={uploading}
                                >
                                    <X className="h-4 w-4" />
                                </Button>
                            </div>
                        ))}
                    </div>

                    {uploadProgress > 0 && (
                        <div className="space-y-2">
                            <div className="flex justify-between text-sm">
                                <span>Subiendo...</span>
                                <span>{uploadProgress}%</span>
                            </div>
                            <Progress value={uploadProgress} />
                        </div>
                    )}
                </div>
            )}
        </div>
    );
}
