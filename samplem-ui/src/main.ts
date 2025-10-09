import { invoke } from "@tauri-apps/api/core";
import { listen, UnlistenFn } from "@tauri-apps/api/event"; // <-- import UnlistenFn
import { open } from "@tauri-apps/plugin-dialog";            // v2 dialog plugin

function byId<T extends HTMLElement>(id: string): T {
  const el = document.getElementById(id);
  if (!el) throw new Error(`Missing element #${id}`);
  return el as T;
}

const folderInput  = byId<HTMLInputElement>("folder");
const chooseBtn    = byId<HTMLButtonElement>("choose");
const runBtn       = byId<HTMLButtonElement>("run");
const normalizeEl  = byId<HTMLInputElement>("normalize");
const trimEl       = byId<HTMLInputElement>("trim");
const layoutEl     = byId<HTMLSelectElement>("layout");
const logEl        = byId<HTMLTextAreaElement>("log");
const dropArea     = byId<HTMLDivElement>("drop");

// Choose folder via dialog
chooseBtn.addEventListener("click", async () => {
  const sel = await open({ directory: true, multiple: false }); // string | string[] | null
  if (typeof sel === "string") {
    folderInput.value = sel;
  } else if (Array.isArray(sel) && sel.length > 0) {
    folderInput.value = sel[0];
  }
});

// Run Samplem
runBtn.addEventListener("click", async () => {
  if (!folderInput.value) {
    logEl.value = "Please select a folder.\n";
    return;
  }
  runBtn.disabled = true;
  logEl.value = "";

  let unlisten: UnlistenFn | undefined;
  try {
    // Stream logs from Rust
    unlisten = await listen<string>("samplem-log", (e) => {
      logEl.value += e.payload + "\n";
      logEl.scrollTop = logEl.scrollHeight;
    });

    const code = await invoke<number>("run_samplem", {
      path: folderInput.value,
      normalize: normalizeEl.checked,
      trim: trimEl.checked,
      layout: layoutEl.value,
    });

    logEl.value += `\nExit code: ${code}\n`;
  } catch (e) {
    logEl.value += `Error: ${String(e)}\n`;
  } finally {
    if (unlisten) await unlisten();
    runBtn.disabled = false;
  }
});

// Accept system file drops (Tauri v2 payload is string[])
listen<string[]>("tauri://file-drop", (e) => {
  const paths = e.payload;
  if (Array.isArray(paths) && paths.length > 0) {
    folderInput.value = paths[0];
  }
});

// Visual hover effect for the drop zone
["dragenter", "dragover"].forEach((ev) => {
  dropArea.addEventListener(
    ev,
    (e) => {
      e.preventDefault();
      dropArea.classList.add("hover");
    },
    false
  );
});
["dragleave", "drop"].forEach((ev) => {
  dropArea.addEventListener(
    ev,
    (e) => {
      e.preventDefault();
      dropArea.classList.remove("hover");
    },
    false
  );
});
