/*
  Warnings:

  - A unique constraint covering the columns `[phone_number]` on the table `users` will be added. If there are existing duplicate values, this will fail.

*/
-- DropForeignKey
ALTER TABLE `login_history` DROP FOREIGN KEY `login_history_user_id_fkey`;

-- AlterTable
ALTER TABLE `login_history` ADD COLUMN `email` VARCHAR(255) NULL,
    MODIFY `user_id` INTEGER NULL,
    MODIFY `ip_address` VARCHAR(45) NULL,
    MODIFY `user_agent` VARCHAR(500) NULL,
    MODIFY `device_name` VARCHAR(255) NULL;

-- AlterTable
ALTER TABLE `users` ADD COLUMN `phone_number` VARCHAR(20) NULL,
    ADD COLUMN `phone_verified` BOOLEAN NOT NULL DEFAULT false,
    MODIFY `email` VARCHAR(255) NULL;

-- AlterTable
ALTER TABLE `verification_codes` MODIFY `type` ENUM('EMAIL_VERIFY', 'PHONE_VERIFY', 'OTP_LOGIN', 'PASSWORD_RESET') NOT NULL;

-- CreateIndex
CREATE UNIQUE INDEX `users_phone_number_key` ON `users`(`phone_number`);

-- AddForeignKey
ALTER TABLE `login_history` ADD CONSTRAINT `login_history_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
