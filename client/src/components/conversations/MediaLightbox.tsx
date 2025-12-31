import { X, Download } from 'lucide-react';
import { useEffect } from 'react';

interface MediaLightboxProps {
    mediaUrl: string;
    mediaType: 'image' | 'video';
    onClose: () => void;
    onDownload?: () => void;
}

export default function MediaLightbox({ mediaUrl, mediaType, onClose, onDownload }: MediaLightboxProps) {
    useEffect(() => {
        const handleEscape = (e: KeyboardEvent) => {
            if (e.key === 'Escape') {
                onClose();
            }
        };

        document.addEventListener('keydown', handleEscape);
        document.body.style.overflow = 'hidden';

        return () => {
            document.removeEventListener('keydown', handleEscape);
            document.body.style.overflow = 'unset';
        };
    }, [onClose]);

    return (
        <div
            className="fixed inset-0 z-50 flex items-center justify-center bg-black/90 backdrop-blur-sm"
            onClick={onClose}
        >
            <div className="absolute top-4 right-4 flex gap-2 z-10">
                {onDownload && (
                    <button
                        onClick={(e) => {
                            e.stopPropagation();
                            onDownload();
                        }}
                        className="p-2 bg-white/10 hover:bg-white/20 rounded-full transition-colors"
                        title="Download"
                    >
                        <Download className="h-6 w-6 text-white" />
                    </button>
                )}
                <button
                    onClick={onClose}
                    className="p-2 bg-white/10 hover:bg-white/20 rounded-full transition-colors"
                    title="Close (Esc)"
                >
                    <X className="h-6 w-6 text-white" />
                </button>
            </div>

            <div
                className="max-w-[90vw] max-h-[90vh] relative"
                onClick={(e) => e.stopPropagation()}
            >
                {mediaType === 'image' ? (
                    <img
                        src={mediaUrl}
                        alt="Preview"
                        className="max-w-full max-h-[90vh] object-contain rounded-lg"
                        crossOrigin="anonymous"
                    />
                ) : (
                    <video
                        src={mediaUrl}
                        controls
                        autoPlay
                        className="max-w-full max-h-[90vh] object-contain rounded-lg"
                        crossOrigin="anonymous"
                    />
                )}
            </div>
        </div>
    );
}
