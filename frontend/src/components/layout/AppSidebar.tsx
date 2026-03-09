import { Link, useLocation } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { useTheme } from '@/contexts/ThemeContext';
import { useIsMobile } from '@/hooks/use-mobile';
import {
  LayoutDashboard, ShoppingCart, Package, BarChart3,
  Users, LogOut, Settings, ChevronLeft, ChevronRight, Store,
  Menu, X, Moon, Sun, Maximize, Minimize
} from 'lucide-react';
import { useState } from 'react';
import { cn } from '@/lib/utils';

const AppSidebar = () => {
  const { user, logout } = useAuth();
  const { theme, toggleTheme, isFullscreen, toggleFullscreen } = useTheme();
  const location = useLocation();
  const isMobile = useIsMobile();
  const [collapsed, setCollapsed] = useState(false);
  const [mobileOpen, setMobileOpen] = useState(false);

  if (!user) return null;

  const navItems = [
    { icon: LayoutDashboard, label: 'Dashboard', path: '/dashboard', roles: ['super_admin', 'owner', 'cashier'] },
    { icon: ShoppingCart, label: 'Point of Sale', path: '/pos', roles: ['super_admin', 'owner', 'cashier'] },
    { icon: Package, label: 'Inventory', path: '/inventory', roles: ['super_admin', 'owner'] },
    { icon: BarChart3, label: 'Reports', path: '/reports', roles: ['super_admin', 'owner', 'cashier'] },
    { icon: Users, label: 'Users', path: '/users', roles: ['super_admin'] },
    { icon: Settings, label: 'Settings', path: '/settings', roles: ['super_admin', 'owner'] },
  ];

  const filteredNav = navItems.filter(item => item.roles.includes(user.role));

  const roleLabel = {
    super_admin: 'Super Admin',
    owner: 'Owner',
    cashier: 'Cashier',
  };

  const handleNavClick = () => {
    if (isMobile) setMobileOpen(false);
  };

  // Mobile: hamburger bar + slide-over drawer
  if (isMobile) {
    return (
      <>
        {/* Top bar */}
        <div className="fixed top-0 left-0 right-0 h-14 sidebar-gradient border-b border-sidebar-border flex items-center justify-between px-4 z-50">
          <div className="flex items-center gap-2">
            <button onClick={() => setMobileOpen(true)} className="text-sidebar-foreground hover:text-sidebar-primary transition-colors">
              <Menu className="w-5 h-5" />
            </button>
            <div className="flex items-center gap-2">
              <div className="w-7 h-7 rounded-lg pos-gradient flex items-center justify-center shadow-md ring-2 ring-yellow-400/20">
                <Store className="w-3.5 h-3.5 text-white" />
              </div>
              <span className="text-sm font-bold text-white tracking-wide">MyPOS</span>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <button onClick={toggleTheme} className="p-2 text-sidebar-foreground hover:text-sidebar-accent-foreground">
              {theme === 'dark' ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
            </button>
            <button onClick={toggleFullscreen} className="p-2 text-sidebar-foreground hover:text-sidebar-accent-foreground">
              {isFullscreen ? <Minimize className="w-4 h-4" /> : <Maximize className="w-4 h-4" />}
            </button>
          </div>
        </div>

        {/* Overlay */}
        {mobileOpen && (
          <div className="fixed inset-0 bg-black/50 z-50" onClick={() => setMobileOpen(false)} />
        )}

        {/* Slide-over sidebar */}
        <aside className={cn(
          "fixed top-0 left-0 h-screen w-64 sidebar-gradient border-r border-sidebar-border z-50 flex flex-col transition-transform duration-300 shadow-2xl",
          mobileOpen ? "translate-x-0" : "-translate-x-full"
        )}>
          <div className="flex items-center justify-between px-4 h-14 border-b border-sidebar-border">
            <div className="flex items-center gap-2">
              <div className="w-7 h-7 rounded-lg pos-gradient flex items-center justify-center shadow-md ring-2 ring-yellow-400/20">
                <Store className="w-3.5 h-3.5 text-white" />
              </div>
              <span className="text-sm font-bold text-white tracking-wide">MyPOS</span>
            </div>
            <button onClick={() => setMobileOpen(false)} className="text-sidebar-foreground">
              <X className="w-5 h-5" />
            </button>
          </div>

          <nav className="flex-1 py-4 px-2 space-y-1 overflow-auto">
            {filteredNav.map(item => {
              const isActive = location.pathname === item.path;
              return (
                <Link
                  key={item.path}
                  to={item.path}
                  onClick={handleNavClick}
                  className={cn(
                    "flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm transition-all duration-200 relative",
                    isActive
                      ? "bg-sidebar-primary/15 text-sidebar-primary font-semibold nav-active-bar shadow-sm"
                      : "text-sidebar-foreground hover:bg-sidebar-accent hover:text-sidebar-accent-foreground"
                  )}
                >
                  <item.icon className={cn("w-5 h-5 flex-shrink-0", isActive && "drop-shadow-sm")} />
                  <span>{item.label}</span>
                </Link>
              );
            })}
          </nav>

          <div className="border-t border-sidebar-border p-3">
            <div className="flex items-center gap-3 mb-3">
              <div className="w-8 h-8 rounded-full pos-gradient flex items-center justify-center ring-2 ring-yellow-400/30">
                <span className="text-xs font-bold text-white">
                  {user.name.charAt(0)}
                </span>
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-xs font-medium text-sidebar-accent-foreground truncate">{user.name}</p>
                <p className="text-[10px] text-sidebar-foreground">{roleLabel[user.role]}</p>
              </div>
            </div>
            <button
              onClick={logout}
              className="flex items-center gap-2 px-3 py-2 rounded-lg text-sm text-sidebar-foreground hover:bg-destructive/20 hover:text-destructive transition-colors w-full"
            >
              <LogOut className="w-4 h-4" />
              <span>Logout</span>
            </button>
          </div>
        </aside>
      </>
    );
  }

  // Desktop sidebar
  return (
    <aside className={cn(
      "sidebar-gradient h-screen flex flex-col border-r border-sidebar-border transition-all duration-300 fixed left-0 top-0 z-40 shadow-2xl",
      collapsed ? "w-16" : "w-64"
    )}>
      <div className="flex items-center gap-3 px-4 h-16 border-b border-sidebar-border">
        <div className="w-8 h-8 rounded-lg pos-gradient flex items-center justify-center flex-shrink-0 shadow-md ring-2 ring-yellow-400/20">
          <Store className="w-4 h-4 text-white" />
        </div>
        {!collapsed && (
          <div className="animate-fade-in">
            <h1 className="text-sm font-bold text-white tracking-wide">MyPOS</h1>
            <p className="text-[10px] text-sidebar-foreground tracking-wider uppercase">Inventory & Sales</p>
          </div>
        )}
      </div>

      <nav className="flex-1 py-4 px-2 space-y-1">
        {filteredNav.map(item => {
          const isActive = location.pathname === item.path;
          return (
            <Link
              key={item.path}
              to={item.path}
              className={cn(
                "flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm transition-all duration-200 relative",
                isActive
                  ? "bg-sidebar-primary/15 text-sidebar-primary font-semibold nav-active-bar shadow-sm"
                  : "text-sidebar-foreground hover:bg-sidebar-accent hover:text-sidebar-accent-foreground"
              )}
            >
              <item.icon className={cn("w-5 h-5 flex-shrink-0", isActive && "drop-shadow-sm")} />
              {!collapsed && <span className="animate-fade-in">{item.label}</span>}
            </Link>
          );
        })}
      </nav>

      {/* Theme & Fullscreen toggles */}
      <div className="px-2 py-2 space-y-1 border-t border-sidebar-border">
        <button
          onClick={toggleTheme}
          className="flex items-center gap-3 px-3 py-2 rounded-lg text-sm text-sidebar-foreground hover:bg-sidebar-accent hover:text-sidebar-accent-foreground transition-colors w-full"
        >
          {theme === 'dark' ? <Sun className="w-5 h-5 flex-shrink-0" /> : <Moon className="w-5 h-5 flex-shrink-0" />}
          {!collapsed && <span className="animate-fade-in">{theme === 'dark' ? 'Light Mode' : 'Dark Mode'}</span>}
        </button>
        <button
          onClick={toggleFullscreen}
          className="flex items-center gap-3 px-3 py-2 rounded-lg text-sm text-sidebar-foreground hover:bg-sidebar-accent hover:text-sidebar-accent-foreground transition-colors w-full"
        >
          {isFullscreen ? <Minimize className="w-5 h-5 flex-shrink-0" /> : <Maximize className="w-5 h-5 flex-shrink-0" />}
          {!collapsed && <span className="animate-fade-in">{isFullscreen ? 'Exit Fullscreen' : 'Fullscreen'}</span>}
        </button>
      </div>

      <div className="border-t border-sidebar-border p-3">
        {!collapsed && (
          <div className="flex items-center gap-3 mb-3 animate-fade-in">
            <div className="w-8 h-8 rounded-full pos-gradient flex items-center justify-center ring-2 ring-yellow-400/30">
              <span className="text-xs font-bold text-white">
                {user.name.charAt(0)}
              </span>
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-xs font-medium text-sidebar-accent-foreground truncate">{user.name}</p>
              <p className="text-[10px] text-sidebar-foreground">{roleLabel[user.role]}</p>
            </div>
          </div>
        )}
        <div className="flex items-center gap-1">
          <button
            onClick={logout}
            className="flex items-center gap-2 px-3 py-2 rounded-lg text-sm text-sidebar-foreground hover:bg-destructive/20 hover:text-destructive transition-colors flex-1"
          >
            <LogOut className="w-4 h-4" />
            {!collapsed && <span>Logout</span>}
          </button>
          <button
            onClick={() => setCollapsed(!collapsed)}
            className="p-2 rounded-lg text-sidebar-foreground hover:bg-sidebar-accent transition-colors"
          >
            {collapsed ? <ChevronRight className="w-4 h-4" /> : <ChevronLeft className="w-4 h-4" />}
          </button>
        </div>
      </div>
    </aside>
  );
};

export default AppSidebar;
