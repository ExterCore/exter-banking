CREATE TABLE IF NOT EXISTS `accounts` (
  `identifier` varchar(50) NOT NULL,
  `id` varchar(50) NOT NULL DEFAULT '',
  `name` longtext NOT NULL,
  `balance` bigint(20) NOT NULL DEFAULT 0,
  `transactions` longtext NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;