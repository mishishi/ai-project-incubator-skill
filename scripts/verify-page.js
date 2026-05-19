#!/usr/bin/env node
/**
 * verify-page.js — 一次性页面冒烟测试
 * Usage: node verify-page.js {url}
 * Exit: 0=通过, 1=有console.error, 2=其他错误
 */
const puppeteer = require('puppeteer');

(async () => {
  const url = process.argv[2] || process.exit(2);
  
  let browser;
  try {
    browser = await puppeteer.launch({
      headless: 'new',
      args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage']
    });
    
    const page = await browser.newPage();
    
    const errors = [];
    page.on('console', msg => {
      if (msg.type() === 'error') {
        const text = msg.text();
        // Ignore resource loading errors (404s for images/fonts)
        if (text.includes('Failed to load resource') && text.includes('404')) return;
        // Ignore connection refused — these are local dev services (Ollama etc.)
        // not application errors
        if (text.includes('ERR_CONNECTION_REFUSED') || text.includes('net::ERR_CONNECTION_REFUSED')) return;
        errors.push(text);
      }
    });
    page.on('pageerror', err => {
      if (err.message.includes('ERR_CONNECTION_REFUSED')) return;
      errors.push(err.message);
    });
    
    await page.goto(url, { waitUntil: 'networkidle0', timeout: 15000 });
    
    // Wait a bit for JS to execute
    await new Promise(r => setTimeout(r, 2000));
    
    await browser.close();
    browser = null;
    
    if (errors.length > 0) {
      console.error('Console errors found:');
      errors.forEach(e => console.error(' -', e));
      process.exit(1);
    }
    
    console.log('OK: no console errors');
    process.exit(0);
    
  } catch (err) {
    if (browser) await browser.close().catch(() => {});
    console.error('Error:', err.message);
    process.exit(2);
  }
})();