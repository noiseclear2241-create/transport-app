import { useEffect, useRef, useState } from "react";

const PX_PER_MM = 96 / 25.4;

/**
 * Displays a fixed physical-size (mm) receipt template scaled down to fit the
 * available width, without affecting the true size html2canvas captures.
 */
export default function PreviewFrame({
  widthMm,
  heightMm,
  children,
}: {
  widthMm: number;
  heightMm: number;
  children: React.ReactNode;
}) {
  const containerRef = useRef<HTMLDivElement>(null);
  const [scale, setScale] = useState(1);

  const naturalWidth = widthMm * PX_PER_MM;
  const naturalHeight = heightMm * PX_PER_MM;

  useEffect(() => {
    const el = containerRef.current;
    if (!el) return;
    const update = () => setScale(Math.min(1, el.clientWidth / naturalWidth));
    update();
    const observer = new ResizeObserver(update);
    observer.observe(el);
    return () => observer.disconnect();
  }, [naturalWidth]);

  return (
    <div ref={containerRef} style={{ width: "100%", overflow: "hidden" }}>
      <div style={{ width: naturalWidth * scale, height: naturalHeight * scale }}>
        <div
          style={{
            width: naturalWidth,
            height: naturalHeight,
            transform: `scale(${scale})`,
            transformOrigin: "top left",
            boxShadow: "0 0 0 1px #ddd, 0 4px 12px rgba(0,0,0,0.08)",
          }}
        >
          {children}
        </div>
      </div>
    </div>
  );
}
