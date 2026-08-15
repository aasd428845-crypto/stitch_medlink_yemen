import { Bell, Box, ClipboardList, Grid2X2, Headphones, Home, Package, Truck, UserRound, Wallet } from "lucide-react";
import type { ReactNode } from "react";

export function TopBar({ role: _role, onBell }: { role: string; onBell: () => void }) {
  return <div className="ml-top"><div className="ml-brand"><div className="ml-mark"><Box size={19}/></div><div><strong>MEDLINK</strong><small>HEALTH OPERATIONS</small></div></div><button className="ml-icon-btn" onClick={onBell} aria-label="الإشعارات"><Bell size={17}/></button></div>;
}

export function Nav({ role, active, onChange }: { role: "client"|"branch"|"driver"; active: string; onChange: (key: string) => void }) {
  const items = role === "client" ? [["home","الرئيسية",Home],["catalog","الكتالوج",Grid2X2],["orders","طلباتي",ClipboardList],["profile","حسابي",UserRound]] : role === "branch" ? [["dashboard","الموجز",Home],["orders","الطلبات",ClipboardList],["inventory","المخزون",Package],["drivers","السائقون",Truck]] : [["orders","التوصيلات",Truck],["earnings","الأرباح",Wallet],["chat","الدعم",Headphones]];
  return <nav className={`ml-nav ${role === "driver" ? "three" : ""}`}>{items.map(([key,label,Icon]) => <button key={key as string} className={active === key ? "active" : ""} onClick={() => onChange(key as string)}><Icon size={18} strokeWidth={1.8}/><span>{label as string}</span></button>)}</nav>;
}

export function Screen({ children }: { children: ReactNode }) { return <div className="medlink-frame"><div className="ml-phone">{children}</div></div>; }
export function Toast({ text, onClose }: { text: string; onClose: () => void }) { return <button className="ml-toast" onClick={onClose}>{text}</button>; }