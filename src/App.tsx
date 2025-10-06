import React, { useState } from 'react';
import { Header } from './components/Header';
import { HomePage } from './components/HomePage';
import { PricingPage } from './components/PricingPage';
import { RegisterPage } from './components/RegisterPage';
import { LoginPage } from './components/LoginPage';
import { BrowsePage } from './components/BrowsePage';
import { AboutPage } from './components/AboutPage';

function App() {
  const [currentPage, setCurrentPage] = useState('home');

  const renderPage = () => {
    switch (currentPage) {
      case 'home':
        return <HomePage onPageChange={setCurrentPage} />;
      case 'pricing':
        return <PricingPage onPageChange={setCurrentPage} />;
      case 'register':
        return <RegisterPage onPageChange={setCurrentPage} />;
      case 'login':
        return <LoginPage onPageChange={setCurrentPage} />;
      case 'browse':
        return <BrowsePage onPageChange={setCurrentPage} />;
      case 'about':
        return <AboutPage onPageChange={setCurrentPage} />;
      default:
        return <HomePage onPageChange={setCurrentPage} />;
    }
  };

  return (
    <div className="min-h-screen bg-gray-900">
      {/* GitOps Deployment Banner */}
      <div className="bg-gradient-to-r from-green-500 via-blue-500 to-purple-600 text-white py-2 px-4 text-center font-semibold shadow-lg animate-pulse">
        🚀 Live Deployment | GitOps Pipeline: GitHub Actions → ArgoCD → EKS | Automated ✨
      </div>
      <Header currentPage={currentPage} onPageChange={setCurrentPage} />
      {renderPage()}
    </div>
  );
}

export default App;// Email notification test - Mon Oct  6 21:40:10 IST 2025
