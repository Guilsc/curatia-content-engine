const API_VERSION = "1";
const DEFAULT_LIMIT = 3;
const MAX_LIMIT = 20;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "content-type",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
};

type PublicationRow = {
  public_id: string;
  channel: string;
  title: string;
  summary: string;
  category: string | null;
  url: string;
  published_at: string;
};

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  if (request.method !== "GET") {
    return jsonResponse(
      { version: API_VERSION, error: "Method not allowed" },
      405,
      { Allow: "GET" },
    );
  }

  const requestUrl = new URL(request.url);
  const channel = requestUrl.searchParams.get("channel")?.trim().toLowerCase();
  const portfolio = requestUrl.searchParams.get("portfolio");
  const limit = parseLimit(requestUrl.searchParams.get("limit"));

  if (portfolio !== null && portfolio !== "true") {
    return jsonResponse(
      { version: API_VERSION, error: "portfolio must be true" },
      400,
    );
  }

  if (limit === null) {
    return jsonResponse(
      { version: API_VERSION, error: `limit must be an integer from 1 to ${MAX_LIMIT}` },
      400,
    );
  }

  if (channel && channel !== "linkedin") {
    return jsonResponse({ version: API_VERSION, publications: [] });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");

    if (!supabaseUrl) {
      throw new Error("SUPABASE_URL is not available");
    }

    const databaseUrl = new URL("/rest/v1/portfolio_publications", supabaseUrl);
    databaseUrl.searchParams.set(
      "select",
      "public_id,channel,title,summary,category,url,published_at",
    );
    databaseUrl.searchParams.set("portfolio", "eq.true");
    databaseUrl.searchParams.set("order", "published_at.desc");
    databaseUrl.searchParams.set("limit", String(limit));

    if (channel) {
      databaseUrl.searchParams.set("channel", `eq.${channel}`);
    }

    const response = await fetch(databaseUrl, {
      headers: databaseHeaders(),
    });

    if (!response.ok) {
      console.error(
        "portfolio_publications query failed",
        response.status,
        (await response.text()).slice(0, 500),
      );
      return jsonResponse(
        { version: API_VERSION, error: "Publication source unavailable" },
        502,
      );
    }

    const rows = (await response.json()) as PublicationRow[];

    return jsonResponse({
      version: API_VERSION,
      publications: rows.map((row) => ({
        id: row.public_id,
        channel: row.channel,
        title: row.title,
        summary: row.summary,
        category: row.category,
        url: row.url,
        publishedAt: row.published_at,
      })),
    });
  } catch (error) {
    console.error("publications-v1 error", error);
    return jsonResponse(
      { version: API_VERSION, error: "Publication source unavailable" },
      502,
    );
  }
});

function parseLimit(value: string | null): number | null {
  if (value === null) {
    return DEFAULT_LIMIT;
  }

  if (!/^\d+$/.test(value)) {
    return null;
  }

  const parsed = Number(value);

  if (!Number.isSafeInteger(parsed) || parsed < 1 || parsed > MAX_LIMIT) {
    return null;
  }

  return parsed;
}

function databaseHeaders(): Record<string, string> {
  const secretKeys = Deno.env.get("SUPABASE_SECRET_KEYS");

  if (secretKeys) {
    try {
      const parsed = JSON.parse(secretKeys) as Record<string, string>;
      const secretKey = parsed.default;

      if (secretKey) {
        return {
          Accept: "application/json",
          apikey: secretKey,
        };
      }
    } catch (error) {
      console.warn("Could not parse SUPABASE_SECRET_KEYS", error);
    }
  }

  const legacyServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!legacyServiceRoleKey) {
    throw new Error("No Supabase server credential is available");
  }

  return {
    Accept: "application/json",
    apikey: legacyServiceRoleKey,
    Authorization: `Bearer ${legacyServiceRoleKey}`,
  };
}

function jsonResponse(
  body: unknown,
  status = 200,
  extraHeaders: Record<string, string> = {},
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      ...extraHeaders,
      "Content-Type": "application/json; charset=utf-8",
      "Cache-Control": "public, max-age=300, stale-while-revalidate=3600",
    },
  });
}
