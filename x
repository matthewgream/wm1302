diff --git a/packet_forwarder/src/lora_pkt_fwd.c b/packet_forwarder/src/lora_pkt_fwd.c
index 53661de..6bcb972 100644
--- a/packet_forwarder/src/lora_pkt_fwd.c
+++ b/packet_forwarder/src/lora_pkt_fwd.c
@@ -3183,11 +3183,19 @@ void thread_down(void) {
             /* check TX power before trying to queue packet, send a warning if not supported */
             if (jit_result == JIT_ERROR_OK) {
                 i = get_tx_gain_lut_index(txpkt.rf_chain, txpkt.rf_power, &tx_lut_idx);
-                if ((i < 0) || (txlut[txpkt.rf_chain].lut[tx_lut_idx].rf_power != txpkt.rf_power)) {
+                if (i < 0) {
+                    /* No LUT entry at or below the requested power. get_tx_gain_lut_index() falls back
+                     * to index 0, which is not necessarily lower than what was requested, so proceeding
+                     * would radiate ABOVE the power the server asked for. That power is derived from a
+                     * regulatory limit, so exceeding it is not a preference to be warned about: reject
+                     * the downlink and tell the server why. */
+                    printf("ERROR: Packet REJECTED, no TX gain LUT entry at or below the requested power (%ddBm, from %ddBm requested less %ddBi antenna_gain)\n", txpkt.rf_power, txpkt.rf_power + antenna_gain, antenna_gain);
+                    jit_result = JIT_ERROR_TX_POWER;
+                } else if (txlut[txpkt.rf_chain].lut[tx_lut_idx].rf_power != txpkt.rf_power) {
                     /* this RF power is not supported, throw a warning, and use the closest lower power supported */
                     warning_result = JIT_ERROR_TX_POWER;
                     warning_value = (int32_t)txlut[txpkt.rf_chain].lut[tx_lut_idx].rf_power;
-                    printf("WARNING: Requested TX power is not supported (%ddBm), actual power used: %ddBm\n", txpkt.rf_power, warning_value);
+                    printf("WARNING: Requested TX power is not supported (%ddBm, from %ddBm requested less %ddBi antenna_gain), actual power used: %ddBm\n", txpkt.rf_power, txpkt.rf_power + antenna_gain, antenna_gain, warning_value);
                     txpkt.rf_power = txlut[txpkt.rf_chain].lut[tx_lut_idx].rf_power;
                 }
             }
