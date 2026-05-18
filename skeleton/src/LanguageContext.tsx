import { createContext, useContext, useState, useCallback, type ReactNode } from 'react';
import { en } from './i18n/en';
import { zh } from './i18n/zh';

export type Language = 'en' | 'zh';
type TranslationDict = typeof en;

interface LanguageContextValue {
  lang: Language;
  t: TranslationDict;
  setLang: (lang: Language) => void;
  toggleLang: () => void;
}

const LanguageContext = createContext<LanguageContextValue | null>(null);

export function LanguageProvider({ children }: { children: ReactNode }) {
  // TODO: replace {project-name} with actual project name for storage key
  const [lang, setLang] = useState<Language>(() => {
    const stored = localStorage.getItem('{project-name}_lang');
    return stored === 'en' ? 'en' : 'zh'; // default: zh
  });

  const toggleLang = useCallback(() => {
    setLang(prev => {
      const next: Language = prev === 'en' ? 'zh' : 'en';
      localStorage.setItem('{project-name}_lang', next);
      return next;
    });
  }, []);

  const t = lang === 'en' ? en : zh;

  return (
    <LanguageContext.Provider value={{ lang, t, setLang, toggleLang }}>
      {children}
    </LanguageContext.Provider>
  );
}

export function useLanguage() {
  const ctx = useContext(LanguageContext);
  if (!ctx) throw new Error('useLanguage must be used within LanguageProvider');
  return ctx;
}