import { NextRequest, NextResponse } from "next/server";

export function proxy(request: NextRequest) {
  const sessionToken =
    request.cookies.get("__Secure-authjs.session-token") ??
    request.cookies.get("authjs.session-token");

  const isLoginPath = request.nextUrl.pathname === "/admin/login";

  if (!isLoginPath && !sessionToken) {
    return NextResponse.redirect(new URL("/admin/login", request.nextUrl.origin));
  }

  if (isLoginPath && sessionToken) {
    return NextResponse.redirect(new URL("/admin", request.nextUrl.origin));
  }
}

export const config = {
  matcher: ["/admin/:path*"],
};
