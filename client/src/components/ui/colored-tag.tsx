import { Badge } from '@/components/ui/badge';
import { cn } from '@/lib/utils';

interface ColoredTagProps {
    name: string;
    color?: string;
    onRemove?: () => void;
    className?: string;
    size?: 'sm' | 'md' | 'lg';
}

const DEFAULT_COLORS = [
    '#3B82F6', // blue
    '#10B981', // green
    '#F59E0B', // amber
    '#EF4444', // red
    '#8B5CF6', // purple
    '#EC4899', // pink
    '#06B6D4', // cyan
    '#F97316', // orange
    '#14B8A6', // teal
    '#84CC16', // lime
    '#A855F7', // violet
    '#F43F5E', // rose
    '#0EA5E9', // sky
    '#22C55E', // emerald
    '#EAB308', // yellow
    '#6366F1', // indigo
];

function getColorForTag(tagName: string, providedColor?: string): string {
    if (providedColor) return providedColor;

    // Generate consistent color based on tag name
    let hash = 0;
    for (let i = 0; i < tagName.length; i++) {
        hash = tagName.charCodeAt(i) + ((hash << 5) - hash);
    }
    return DEFAULT_COLORS[Math.abs(hash) % DEFAULT_COLORS.length];
}

function getContrastColor(hexColor: string): string {
    // Remove # if present
    const hex = hexColor.replace('#', '');

    // Convert to RGB
    const r = parseInt(hex.substr(0, 2), 16);
    const g = parseInt(hex.substr(2, 2), 16);
    const b = parseInt(hex.substr(4, 2), 16);

    // Calculate luminance
    const luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;

    return luminance > 0.5 ? '#000000' : '#FFFFFF';
}

export function ColoredTag({ name, color, onRemove, className, size = 'md' }: ColoredTagProps) {
    const tagColor = getColorForTag(name, color);
    const textColor = getContrastColor(tagColor);

    const sizeClasses = {
        sm: 'px-1.5 py-0 text-xs h-5',
        md: 'px-2 py-0.5 text-xs h-6',
        lg: 'px-2.5 py-1 text-sm h-7',
    };

    return (
        <Badge
            className={cn(
                'flex items-center gap-1 border-0',
                sizeClasses[size],
                className
            )}
            style={{
                backgroundColor: tagColor,
                color: textColor,
            }}
        >
            <span>{name}</span>
            {onRemove && (
                <button
                    onClick={(e) => {
                        e.stopPropagation();
                        onRemove();
                    }}
                    className="ml-0.5 rounded-full p-0.5 hover:bg-black/10 transition-colors"
                    aria-label={`Remove ${name} tag`}
                >
                    <svg className="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                    </svg>
                </button>
            )}
        </Badge>
    );
}

export { getColorForTag, getContrastColor, DEFAULT_COLORS };
