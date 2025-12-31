import PropertyList from '@/components/properties/PropertyList';
import Header from '@/components/layout/Header';
import Sidebar from '@/components/layout/Sidebar';

export default function PropertiesPage() {
    return (
        <div className="h-screen flex flex-col overflow-hidden font-sans text-gray-800">
            <Header />
            <div className="flex flex-1 overflow-hidden">
                <Sidebar />
                <div className="flex-1 overflow-y-auto">
                    <div className="container mx-auto px-4 py- py-6">
                        <PropertyList />
                    </div>
                </div>
            </div>
        </div>
    );
}
