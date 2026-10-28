"use server";

import { revalidatePath } from "next/cache";

import { getSupabaseAdmin } from "@/lib/supabase";
import { authorizationFor, requireOnboardedSession } from "@/lib/session";
import { assertWorkspaceWrite } from "@/lib/authorization";

export async function saveSettings(formData: FormData) {
  const session = await requireOnboardedSession();
  const workspace = session.workspaces[0];
  if (!workspace) throw new Error("Workspace required.");
  assertWorkspaceWrite(authorizationFor(session, workspace.id));

  const admin = getSupabaseAdmin();
  const displayName = String(formData.get("displayName") ?? "").trim();
  const roleTitle = String(formData.get("roleTitle") ?? "").trim();
  const bio = String(formData.get("bio") ?? "").trim();
  const avatarKey = String(formData.get("avatarKey") ?? "circuit");
  const customInterests = String(formData.get("customInterests") ?? "").split(",").map((v) => v.trim()).filter(Boolean);
  const interests = [...new Set([...formData.getAll("interests").map(String), ...customInterests])];
  const channels = formData.getAll("channels").map(String);
  const primaryChannel = String(formData.get("primaryChannel") ?? "");

  if (!displayName || interests.length === 0) throw new Error("Display name and at least one Discovery Interest are required.");

  const { error: profileError } = await admin.from("profiles").update({
    display_name: displayName,
    role_title: roleTitle || null,
    bio: bio || null,
    avatar_key: avatarKey
  }).eq("user_id", session.userId);
  if (profileError) throw new Error(profileError.message);

  const { error: disableInterestsError } = await admin.from("discovery_interests")
    .update({ active: false }).eq("workspace_id", workspace.id);
  if (disableInterestsError) throw new Error(disableInterestsError.message);

  for (const label of interests) {
    const { error } = await admin.from("discovery_interests").upsert({
      workspace_id: workspace.id,
      label,
      source: "user_added",
      active: true,
      created_by: session.userId
    }, { onConflict: "workspace_id,normalized_label" });
    if (error) throw new Error(error.message);
  }

  const { error: disableChannelsError } = await admin.from("workspace_channels")
    .update({ enabled: false, is_primary: false }).eq("workspace_id", workspace.id);
  if (disableChannelsError) throw new Error(disableChannelsError.message);

  for (const channelKey of channels) {
    const { error } = await admin.from("workspace_channels").upsert({
      workspace_id: workspace.id,
      channel_key: channelKey,
      enabled: true,
      is_primary: channelKey === primaryChannel
    }, { onConflict: "workspace_id,channel_key" });
    if (error) throw new Error(error.message);
  }

  await admin.from("audit_events").insert({
    workspace_id: workspace.id,
    actor_user_id: session.userId,
    event_type: "settings.updated",
    target_type: "workspace",
    target_id: workspace.id
  });

  revalidatePath("/settings");
  revalidatePath("/home");
}
