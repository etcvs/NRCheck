# NRCheck (Nginx/OpenResty Security Auditor)
##本專案由ChatGPT 5.5Instant +Gemini 3快捷 互相檢查撰寫


`NRCheck` 是一個專為 Nginx 與 OpenResty 設計的輕量級、唯讀（Read-only）安全弱點掃描工具。透過自動導出記憶體中實際運行的配置（Active Config）並結合雲端模組化設計，協助維運人員在不影響生產環境的前提下，快速排查已知的資安漏洞與高風險設定。

## 🚀 特色
- **一鍵遠端執行**：無需在伺服器上下載或安裝多餘檔案，隨打隨跑。
- **動態雲端模組**：主腳本自動從 GitHub 抓取最新漏洞偵測模組（如 CVE-2026-42945），即時更新檢測邏輯。
- **安全無副作用**：採用唯讀模式（Read-only），不修改系統檔案、不重啟服務、無任何寫入破壞行為。
- **相容性高**：原生支援 Ubuntu/CentOS/Debian 等多種 Linux 發行版，完美相容純 Nginx 與 OpenResty 環境。

---

## ⚡ 快速開始 (一鍵執行)

在任何安裝有 Nginx/OpenResty 的 Linux 主機上，以 root 或具備 Nginx 讀取權限的身分執行以下指令：

```bash
curl -fsSL https://raw.githubusercontent.com/etcvs/NRCheck/main/nrcheck.sh | sudo bash