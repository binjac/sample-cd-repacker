#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use std::{
  io::{BufRead, BufReader},
  process::{Command, Stdio},
};
use tauri::{AppHandle};      // remove Manager
use tauri::Emitter;          // ADD THIS

#[tauri::command]
async fn run_samplem(
  app: AppHandle,
  path: String,
  normalize: bool,
  trim: bool,
  layout: String,
) -> Result<i32, String> {
  // If samplem isn't in PATH, replace with its absolute path:
  // let mut cmd = Command::new("/usr/local/bin/samplem");
  let mut cmd = Command::new("samplem");

  cmd.arg("repack")
    .arg("--path").arg(path)
    .arg("--normalize").arg(if normalize { "true" } else { "false" })
    .arg("--trim").arg(if trim { "true" } else { "false" })
    .arg("--layout").arg(layout)
    .stdout(Stdio::piped())
    .stderr(Stdio::piped());

  let mut child = cmd.spawn().map_err(|e| e.to_string())?;

  if let Some(stdout) = child.stdout.take() {
    let app_clone = app.clone();
    std::thread::spawn(move || {
      let reader = BufReader::new(stdout);
      for line in reader.lines() {
        if let Ok(line) = line {
          let _ = app_clone.emit("samplem-log", line);
        }
      }
    });
  }

  if let Some(stderr) = child.stderr.take() {
    let app_clone = app.clone();
    std::thread::spawn(move || {
      let reader = BufReader::new(stderr);
      for line in reader.lines() {
        if let Ok(line) = line {
          let _ = app_clone.emit("samplem-log", line);
        }
      }
    });
  }

  let status = child.wait().map_err(|e| e.to_string())?;
  Ok(status.code().unwrap_or(-1))
}

fn main() {
  tauri::Builder::default()
    .invoke_handler(tauri::generate_handler![run_samplem])
    .run(tauri::generate_context!())
    .expect("error while running tauri application");
}
