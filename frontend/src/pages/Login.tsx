import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { Store, Eye, EyeOff } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { motion } from 'framer-motion';

const Login = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const { login } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setIsSubmitting(true);
    try {
      const ok = await login(email, password);
      if (ok) {
        navigate('/dashboard');
      } else {
        setError('Invalid credentials. Default password is: password');
      }
    } finally {
      setIsSubmitting(false);
    }
  };

  const demoAccounts = [
    { email: 'admin@pos.com', role: 'Super Admin' },
    { email: 'owner@pos.com', role: 'Owner' },
    { email: 'jane@pos.com', role: 'Cashier' },
  ];

  return (
    <div className="min-h-screen flex bg-background">
      {/* Left panel — deep navy branding */}
      <div
        className="hidden lg:flex lg:w-1/2 items-center justify-center p-12 relative overflow-hidden"
        style={{ background: 'linear-gradient(145deg, hsl(222 100% 30%) 0%, hsl(222 100% 20%) 50%, hsl(205 52% 10%) 100%)' }}
      >
        {/* Subtle gold radial glow */}
        <div
          className="absolute inset-0 opacity-20 pointer-events-none"
          style={{ background: 'radial-gradient(ellipse at 30% 70%, hsl(43 100% 50%) 0%, transparent 60%)' }}
        />
        {/* Decorative circles */}
        <div className="absolute inset-0 overflow-hidden pointer-events-none">
          {[...Array(8)].map((_, i) => (
            <div
              key={i}
              className="absolute rounded-full border border-white/5"
              style={{
                width: `${(i + 2) * 120}px`,
                height: `${(i + 2) * 120}px`,
                top: '50%',
                left: '50%',
                transform: 'translate(-50%, -50%)',
                opacity: 0.4 - i * 0.04,
              }}
            />
          ))}
        </div>
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
          className="relative z-10 text-center"
        >
          <div className="w-24 h-24 rounded-2xl pos-gradient flex items-center justify-center mx-auto mb-8 shadow-2xl ring-4 ring-yellow-400/20">
            <Store className="w-12 h-12 text-white" />
          </div>
          <h1 className="text-5xl font-bold text-white mb-3 tracking-tight">TeraPay</h1>
          <div className="w-16 h-1 rounded-full mx-auto mb-5" style={{ background: 'hsl(43 100% 50%)' }} />
          <p className="text-base text-white/70 max-w-sm leading-relaxed">
            Modern point-of-sale system with barcode scanning, inventory tracking, and real-time sales analytics.
          </p>
          <div className="mt-10 flex justify-center gap-8 text-xs text-white/50">
            <div className="text-center">
              <p className="text-2xl font-bold text-white">99.9<span className="text-yellow-400">%</span></p>
              <p>Uptime</p>
            </div>
            <div className="w-px bg-white/10" />
            <div className="text-center">
              <p className="text-2xl font-bold text-white">10<span className="text-yellow-400">x</span></p>
              <p>Faster</p>
            </div>
            <div className="w-px bg-white/10" />
            <div className="text-center">
              <p className="text-2xl font-bold text-white">24<span className="text-yellow-400">/7</span></p>
              <p>Support</p>
            </div>
          </div>
        </motion.div>
      </div>

      {/* Right panel — login form */}
      <div className="flex-1 flex items-center justify-center p-8 bg-background">
        <motion.div
          initial={{ opacity: 0, x: 20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ duration: 0.5, delay: 0.2 }}
          className="w-full max-w-md"
        >
          <div className="lg:hidden flex items-center gap-3 mb-8">
            <div className="w-10 h-10 rounded-xl pos-gradient flex items-center justify-center shadow-md">
              <Store className="w-5 h-5 text-white" />
            </div>
            <h1 className="text-2xl font-bold text-foreground">TeraPay</h1>
          </div>

          <h2 className="text-2xl font-bold text-foreground mb-1">Welcome back</h2>
          <p className="text-muted-foreground mb-8">Sign in to your account to continue</p>

          <form onSubmit={handleSubmit} className="space-y-5">
            <div className="space-y-2">
              <Label htmlFor="email">Email</Label>
              <Input
                id="email"
                type="email"
                placeholder="Enter your email"
                value={email}
                onChange={e => setEmail(e.target.value)}
                required
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="password">Password</Label>
              <div className="relative">
                <Input
                  id="password"
                  type={showPassword ? 'text' : 'password'}
                  placeholder="Enter your password"
                  value={password}
                  onChange={e => setPassword(e.target.value)}
                  required
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
                >
                  {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
            </div>

            {error && (
              <p className="text-sm text-destructive bg-destructive/10 px-3 py-2 rounded-lg">{error}</p>
            )}

            <Button type="submit" className="w-full" disabled={isSubmitting}>
              {isSubmitting ? 'Signing in…' : 'Sign In'}
            </Button>
          </form>

          {/* Demo accounts */}
          <div className="mt-8 p-4 rounded-xl bg-muted/50 border border-border">
            <p className="text-xs font-medium text-muted-foreground mb-3">Demo Accounts (password: <span className="font-mono">password</span>)</p>
            <div className="space-y-2">
              {demoAccounts.map(acc => (
                <button
                  key={acc.email}
                  onClick={() => { setEmail(acc.email); setPassword('password'); }}
                  className="flex items-center justify-between w-full px-3 py-2 rounded-lg text-sm hover:bg-accent transition-colors"
                >
                  <span className="text-foreground font-mono text-xs">{acc.email}</span>
                  <span className="text-xs text-muted-foreground">{acc.role}</span>
                </button>
              ))}
            </div>
          </div>
        </motion.div>
      </div>
    </div>
  );
};

export default Login;
