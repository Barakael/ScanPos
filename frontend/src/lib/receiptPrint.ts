import { Sale } from '@/types';
import { formatCurrency } from '@/data/mockData';

export interface ReceiptShopInfo {
  name: string;
  address?: string | null;
  phone?: string | null;
}

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

/** Builds the `#__receipt__` HTML used by window.print() */
export function buildReceiptPrintHtml(sale: Sale, shop: ReceiptShopInfo): string {
  const shopName = escapeHtml(shop.name?.trim() || 'Shop');
  const address = shop.address?.trim();
  const phone = shop.phone?.trim();

  const itemRows = sale.items
    .map(
      item => `<div class="item">
        <span>${item.quantity}x ${escapeHtml(item.product.name)}</span>
        <span>${formatCurrency(item.product.price * item.quantity)}</span>
      </div>`
    )
    .join('');

  return `
    <h2>${shopName}</h2>
    ${address ? `<p class="meta">${escapeHtml(address)}</p>` : ''}
    ${phone ? `<p class="meta">TEL : ${escapeHtml(phone)}</p>` : ''}
    <hr/>
    <p class="meta">Receipt #${escapeHtml(String(sale.id))}</p>
    <p class="meta">${escapeHtml(new Date(sale.timestamp).toLocaleString())}</p>
    <p class="meta">Cashier: ${escapeHtml(sale.cashierName)}</p>
    <hr/>
    ${itemRows}
    <hr/>
    <div class="row total"><span>TOTAL</span><span>${formatCurrency(sale.total)}</span></div>
    <div class="row"><span>Payment</span><span>${escapeHtml(String(sale.paymentMethod))}</span></div>
    <p class="footer">Thank you for your purchase!</p>
    <p class="footer powered">Powered by SmartSell</p>
  `;
}
