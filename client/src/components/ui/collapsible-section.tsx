import { useState, ReactNode } from 'react';
import { ChevronDown } from 'lucide-react';

interface CollapsibleSectionProps {
    title: string;
    children: ReactNode;
    defaultOpen?: boolean;
    className?: string;
}

export function CollapsibleSection({
    title,
    children,
    defaultOpen = true,
    className = ''
}: CollapsibleSectionProps) {
    const [isOpen, setIsOpen] = useState(defaultOpen);

    return (
        <div className={className}>
            <button
                type="button"
                onClick={() => setIsOpen(!isOpen)}
                className="flex items-center justify-between w-full text-left py-2 hover:text-gray-600 transition-colors"
            >
                <span className="font-medium">{title}</span>
                <ChevronDown
                    className={`h-4 w-4 transition-transform ${isOpen ? 'rotate-180' : ''}`}
                />
            </button>

            {isOpen && (
                <div className="pt-2">
                    {children}
                </div>
            )}
        </div>
    );
}
