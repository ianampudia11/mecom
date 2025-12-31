import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Checkbox } from "@/components/ui/checkbox";
import { Plus, Trash2, GripVertical } from "lucide-react";
import { cn } from "@/lib/utils";

interface ChecklistItem {
    id: string;
    text: string;
    completed: boolean;
}

interface TaskChecklistProps {
    items: ChecklistItem[];
    onChange: (items: ChecklistItem[]) => void;
}

export function TaskChecklist({ items, onChange }: TaskChecklistProps) {
    const [newItemText, setNewItemText] = useState("");

    const handleAddItem = () => {
        if (!newItemText.trim()) return;
        const newItem: ChecklistItem = {
            id: crypto.randomUUID(),
            text: newItemText.trim(),
            completed: false
        };
        onChange([...items, newItem]);
        setNewItemText("");
    };

    const handleToggleItem = (id: string, checked: boolean) => {
        onChange(items.map(item =>
            item.id === id ? { ...item, completed: checked } : item
        ));
    };

    const handleDeleteItem = (id: string) => {
        onChange(items.filter(item => item.id !== id));
    };

    const handleTextChange = (id: string, text: string) => {
        onChange(items.map(item =>
            item.id === id ? { ...item, text } : item
        ));
    };

    const handleKeyDown = (e: React.KeyboardEvent) => {
        if (e.key === 'Enter') {
            e.preventDefault();
            handleAddItem();
        }
    };

    return (
        <div className="space-y-3">
            <div className="flex items-center space-x-2">
                <Input
                    placeholder="Add checklist item..."
                    value={newItemText}
                    onChange={(e) => setNewItemText(e.target.value)}
                    onKeyDown={handleKeyDown}
                    className="flex-1"
                />
                <Button
                    type="button"
                    variant="outline"
                    size="icon"
                    onClick={handleAddItem}
                    disabled={!newItemText.trim()}
                >
                    <Plus className="h-4 w-4" />
                </Button>
            </div>

            <div className="space-y-2">
                {items.length === 0 && (
                    <p className="text-sm text-muted-foreground text-center py-2 italic">
                        No items yet
                    </p>
                )}
                {items.map((item) => (
                    <div key={item.id} className="flex items-center gap-2 group p-1 rounded hover:bg-slate-50">
                        <Checkbox
                            checked={item.completed}
                            onCheckedChange={(checked) => handleToggleItem(item.id, checked as boolean)}
                        />
                        <Input
                            value={item.text}
                            onChange={(e) => handleTextChange(item.id, e.target.value)}
                            className={cn(
                                "flex-1 h-8 border-transparent hover:border-input focus:border-input bg-transparent",
                                item.completed && "line-through text-muted-foreground"
                            )}
                        />
                        <Button
                            type="button"
                            variant="ghost"
                            size="icon"
                            className="h-8 w-8 opacity-0 group-hover:opacity-100 transition-opacity text-destructive hover:text-destructive"
                            onClick={() => handleDeleteItem(item.id)}
                        >
                            <Trash2 className="h-4 w-4" />
                        </Button>
                    </div>
                ))}
            </div>

            {items.length > 0 && (
                <div className="text-xs text-muted-foreground pt-1">
                    {items.filter(i => i.completed).length} of {items.length} completed
                </div>
            )}
        </div>
    );
}
