-- AlterTable
ALTER TABLE `cinemas` MODIFY `image_url` TEXT NULL;

-- AlterTable
ALTER TABLE `movies` MODIFY `poster_url` TEXT NOT NULL,
    MODIFY `trailer_url` TEXT NULL;
