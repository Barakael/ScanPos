import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { AuthProvider } from "@/contexts/AuthContext";
import { StoreProvider } from "@/contexts/StoreContext";
import { ThemeProvider } from "@/contexts/ThemeContext";
import { ErrorBoundary } from "@/components/ErrorBoundary";
import ProtectedRoute from "@/components/ProtectedRoute";
import { IOSInstallPrompt } from "@/components/IOSInstallPrompt";
import { useOfflineDetection } from "@/hooks/useOfflineDetection";
import Index from "./pages/Index";
import Login from "./pages/Login";
import Dashboard from "./pages/Dashboard";
import POS from "./pages/POS";
import Inventory from "./pages/Inventory";
import Reports from "./pages/Reports";
import Users from "./pages/Users";
import Settings from "./pages/Settings";
import Shops from "./pages/Shops";
import Staff from "./pages/Staff";
import SystemLogs from "./pages/SystemLogs";
import SystemReports from "./pages/SystemReports";
import Payments from "./pages/Payments";
import Transactions from "./pages/Transactions";
import NotFound from "./pages/NotFound";

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,
      refetchOnWindowFocus: false,
    },
  },
});

function OfflineDetector() {
  useOfflineDetection();
  return null;
}

const App = () => (
  <ErrorBoundary>
    <QueryClientProvider client={queryClient}>
      <TooltipProvider>
        <ThemeProvider>
          <AuthProvider>
            <StoreProvider>
              <Toaster />
              <Sonner />
              <OfflineDetector />
              <IOSInstallPrompt />
              <BrowserRouter>
                <Routes>
                  {/* Public */}
                  <Route path="/" element={<Navigate to="/login" replace />} />
                  <Route path="/login" element={<Login />} />

                  {/* Protected — all authenticated roles */}
                  <Route element={<ProtectedRoute />}>
                    <Route path="/dashboard" element={<Dashboard />} />
                  </Route>

                  {/* Protected — owner + cashier only (operational) */}
                  <Route element={<ProtectedRoute allowedRoles={['owner', 'cashier']} />}>
                    <Route path="/pos" element={<POS />} />
                    <Route path="/inventory" element={<Inventory />} />
                    <Route path="/reports" element={<Reports />} />
                    <Route path="/transactions" element={<Transactions />} />
                  </Route>

                  {/* Protected — super_admin only */}
                  <Route element={<ProtectedRoute allowedRoles={['super_admin']} />}>
                    <Route path="/users" element={<Users />} />
                    <Route path="/shops" element={<Shops />} />
                    <Route path="/logs" element={<SystemLogs />} />
                    <Route path="/system-reports" element={<SystemReports />} />
                  </Route>

                  {/* Protected — owner only */}
                  <Route element={<ProtectedRoute allowedRoles={['owner']} />}>
                    <Route path="/settings" element={<Settings />} />
                    <Route path="/staff" element={<Staff />} />
                  </Route>

                  {/* Protected — super_admin + owner (payments) */}
                  <Route element={<ProtectedRoute allowedRoles={['super_admin', 'owner']} />}>
                    <Route path="/payments" element={<Payments />} />
                  </Route>

                  <Route path="*" element={<NotFound />} />
                </Routes>
              </BrowserRouter>
          </StoreProvider>
        </AuthProvider>
      </ThemeProvider>
    </TooltipProvider>
  </QueryClientProvider>
</ErrorBoundary>
);

export default App;
