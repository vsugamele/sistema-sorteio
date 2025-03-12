
import { Link } from 'react-router-dom';
import { Trophy } from 'lucide-react';
import './logo.css';

interface LogoProps {
  linkTo?: string;
}

export function Logo({ linkTo = '/receipt' }: LogoProps) {
  const LogoContent = () => (
    <>
      <div className="logo-icon-container">
        <Trophy className="logo-icon" />
      </div>
      <div className="logo-text-container">
        <span className="logo-text-primary">SORTEIO</span>
        <span className="logo-text-secondary">DA LAISE</span>
      </div>
    </>
  );

  if (linkTo) {
    return (
      <Link to={linkTo} className="logo-container">
        <LogoContent />
      </Link>
    );
  }

  return (
    <div className="logo-container">
      <LogoContent />
    </div>
  );
}

export default Logo;
