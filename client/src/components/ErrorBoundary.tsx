
import React, { Component, ErrorInfo, ReactNode } from "react";
import { AlertTriangle } from "lucide-react";
import { Button } from "@/components/ui/button";

interface Props {
    children?: ReactNode;
}

interface State {
    hasError: boolean;
    error: Error | null;
    errorInfo: ErrorInfo | null;
}

export class ErrorBoundary extends Component<Props, State> {
    public state: State = {
        hasError: false,
        error: null,
        errorInfo: null
    };

    public static getDerivedStateFromError(error: Error): State {
        return { hasError: true, error, errorInfo: null };
    }

    public componentDidCatch(error: Error, errorInfo: ErrorInfo) {
        console.error("Uncaught error:", error, errorInfo);
        this.setState({ error, errorInfo });
    }

    public render() {
        if (this.state.hasError) {
            return (
                <div className="flex flex-col items-center justify-center min-h-[400px] p-8 bg-red-50 rounded-lg border border-red-200 m-4">
                    <AlertTriangle className="h-12 w-12 text-red-500 mb-4" />
                    <h2 className="text-xl font-bold text-red-800 mb-2">Algo salió mal en el Pipeline</h2>
                    <p className="text-red-600 mb-4">Se ha producido un error al mostrar esta vista.</p>

                    <div className="w-full max-w-2xl bg-white p-4 rounded border border-red-100 overflow-auto max-h-[300px] mb-4">
                        <p className="font-mono text-sm text-red-700 font-bold mb-2">
                            {this.state.error?.toString()}
                        </p>
                        <pre className="font-mono text-xs text-gray-600 whitespace-pre-wrap">
                            {this.state.errorInfo?.componentStack || this.state.error?.stack}
                        </pre>
                    </div>

                    <Button
                        onClick={() => window.location.reload()}
                        variant="default"
                        className="bg-red-600 hover:bg-red-700"
                    >
                        Recargar Página
                    </Button>
                </div>
            );
        }

        return this.props.children;
    }
}
