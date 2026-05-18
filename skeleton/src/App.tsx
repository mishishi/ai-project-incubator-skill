import { BrowserRouter, Routes, Route, useNavigate } from 'react-router-dom';
import { LanguageProvider, useLanguage } from './LanguageContext';

// NOTE: This is a minimal working example. Replace with actual app content.

function App() {
  return (
    <LanguageProvider>
      <Router />
    </LanguageProvider>
  );
}

function Router() {
  const { t, toggleLang } = useLanguage();
  const navigate = useNavigate();

  return (
    <BrowserRouter basename="/{project-name}/">
      <div style={{
        background: '#0F0F0E',
        color: '#E8E4DC',
        minHeight: '100vh',
        padding: '2rem',
        fontFamily: 'Inter, sans-serif'
      }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
          <h1 style={{ color: '#E07A3A', fontSize: '1.5rem', fontWeight: 700, fontFamily: 'Lora, serif' }}>
            {t.app.title}
          </h1>
          <button
            onClick={toggleLang}
            style={{
              background: '#252420',
              border: '1px solid #33302A',
              borderRadius: '12px',
              padding: '8px 16px',
              color: '#E8E4DC',
              cursor: 'pointer',
              fontSize: '0.875rem'
            }}
            aria-label="Toggle language"
          >
            🌐 {t.lang === 'zh' ? 'EN' : '中文'}
          </button>
        </div>

        <div style={{
          background: '#1A1917',
          border: '1px solid #33302A',
          borderRadius: '16px',
          padding: '2rem',
          marginBottom: '1rem'
        }}>
          <h2 style={{ color: '#E8E4DC', fontSize: '1.25rem', marginBottom: '1rem' }}>
            {t.dashboard.title}
          </h2>
          <p style={{ color: '#8A857A' }}>
            {t.dashboard.emptyDesc}
          </p>
        </div>

        <div style={{ color: '#8A857A', fontSize: '0.875rem' }}>
          Incubator Ready — Replace this with actual app content
        </div>
      </div>

      <Routes>
        <Route path="/" element={<div>Home</div>} />
      </Routes>
    </BrowserRouter>
  );
}

export default App;