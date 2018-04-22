INSERT INTO domains (`id`, name, master, last_check, type, notified_serial, `account`) VALUES (1, 'example.com', NULL, NULL, 'MASTER', NULL, NULL);
INSERT INTO records (`id`, domain_id, name, type, content, ttl, prio, change_date, disabled, ordername, `auth`) VALUES
(2, 1, 'example.com', 'SOA', 'ns0.example.com mail.gmail.com. 2018040600 3600 900 604800 86400', 86400, NULL, NULL, 0, NULL, 1),
(3, 1, 'example.com', 'NS', 'ns0.example.com', 86400, 0, NULL, 0, NULL, 1),
(4, 1, 'example.com', 'NS', 'ns1.example.com', 86400, 0, NULL, 0, NULL, 1),
(5, 1, 'example.com', 'A', 'placeA', 86400, 0, NULL, 0, NULL, 1),
(6, 1, 'ns0.example.com', 'A', 'placeNS0', 86400, 0, NULL, 0, NULL, 1),
(7, 1, 'ns1.example.com', 'A', 'placeNS1', 86400, 0, NULL, 0, NULL, 1);