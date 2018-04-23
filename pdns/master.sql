use powerdns;
INSERT INTO domains (name, master, last_check, type, notified_serial, `account`) VALUES ('example.com.com', NULL, NULL, 'MASTER', NULL, NULL);
SELECT id from domains WHERE name='example.com.com' INTO @domain_id;
INSERT INTO records (domain_id, name, type, content, ttl, prio, change_date, disabled, ordername, `auth`) VALUES
(@domain_id, 'example.com.com', 'SOA', 'ns0.example.com.com mail.gmail.com. 2018040600 3600 900 604800 86400', 86400, NULL, NULL, 0, NULL, 1),
(@domain_id, 'example.com.com', 'NS', 'ns0.example.com.com', 86400, 0, NULL, 0, NULL, 1),
(@domain_id, 'example.com.com', 'NS', 'ns1.example.com.com', 86400, 0, NULL, 0, NULL, 1),
(@domain_id, 'example.com.com', 'A', 'placeA', 86400, 0, NULL, 0, NULL, 1),
(@domain_id, 'ns0.example.com.com', 'A', 'placeNS0', 86400, 0, NULL, 0, NULL, 1),
(@domain_id, 'ns1.example.com.com', 'A', 'placeNS1', 86400, 0, NULL, 0, NULL, 1);
