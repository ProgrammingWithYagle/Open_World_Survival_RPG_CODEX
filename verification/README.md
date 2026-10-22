# Verification evidence

`ui_matrix/` contains 130 actual native renderer captures: 26 screens in each of five languages. Its JSON report records the screen names and zero detected layout overflow. These are controlled QA scenarios; the backpack includes test items so icons and long lists can be inspected.

The six MP4s show normal and quarter-speed player, creature and warden animation. They were encoded from 1,080 native captures. Contact sheets show the shipped sprite cells and selected playback frames. They are inspection material, not promotional claims of a human playthrough.

`export_hud_*.png` are fresh standalone Windows game captures. The exported game runs from a copied installation without a source project or installed engine.

`performance.json` records the five-region scenario on the tested Intel Graphics machine. The baseline and intermediate reports retain the evidence behind cache and incremental-streaming fixes. Measurements are specific to the recorded hardware and workload.

Wiki and Project receipts identify the published documentation and development board. Machine-specific logs, temporary extracted builds, raw animation capture frames and per-run ZIP receipts are not committed. Hosted CI provides the current data, asset, gameplay, Windows export and documentation results. See [implementation status](../docs/IMPLEMENTATION_STATUS.md) for scope and limits.
