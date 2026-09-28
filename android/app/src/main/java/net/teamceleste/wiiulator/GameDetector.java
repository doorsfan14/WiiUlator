package net.teamceleste.wiiulator;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.regex.*;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

final class GameDetector {
    static final class Result {
        final String title;
        final String titleId;
        final String region;
        Result(String title, String titleId, String region) {
            this.title = title;
            this.titleId = titleId;
            this.region = region;
        }
    }

    private static final Map<String, String> TITLES = new HashMap<>();
    static {
        add("0005000010101A00", "LEGO City Undercover", "USA");
        add("0005000010101B00", "LEGO City Undercover", "EUR");
        add("0005000010101C00", "New Super Mario Bros. U", "JPN");
        add("0005000010101D00", "New Super Mario Bros. U", "USA");
        add("0005000010101E00", "New Super Mario Bros. U", "EUR");
        add("0005000010101F00", "Nintendo Land", "JPN");
        add("0005000010102000", "Nintendo Land", "USA");
        add("0005000010102100", "Nintendo Land", "EUR");
        add("0005000010102300", "Wii Fit U", "USA");
        add("0005000010102400", "Wii Fit U", "EUR");
        add("000500001010EB00", "Mario Kart 8", "JPN");
        add("000500001010EC00", "Mario Kart 8", "USA");
        add("000500001010ED00", "Mario Kart 8", "EUR");
        add("0005000010144F00", "Super Smash Bros. for Wii U", "USA");
        add("0005000010145000", "Super Smash Bros. for Wii U", "EUR");
    }

    private static void add(String id, String title, String region) {
        TITLES.put(id, title + "\u0000" + region);
    }

    static Result detect(byte[] data, String extension) {
        String titleId = findTitleId(data);
        if (titleId != null) {
            String value = TITLES.get(titleId);
            if (value != null) {
                int split = value.indexOf('\u0000');
                return new Result(value.substring(0, split), titleId, value.substring(split + 1));
            }
            return new Result("Wii U Game", titleId, regionFromId(titleId));
        }

        if (isZip(data)) {
            Result meta = detectMetaXml(data);
            if (meta != null) return meta;
        }

        return new Result("Unknown Wii U Game", "", "");
    }

    private static String findTitleId(byte[] data) {
        String text = new String(data, StandardCharsets.ISO_8859_1).toUpperCase(Locale.ROOT);
        Matcher m = Pattern.compile("000500(?:00|02)[0-9A-F]{8}").matcher(text);
        return m.find() ? m.group() : null;
    }

    private static Result detectMetaXml(byte[] data) {
        try (ZipInputStream zip = new ZipInputStream(new ByteArrayInputStream(data))) {
            ZipEntry e;
            byte[] buffer = new byte[65536];
            while ((e = zip.getNextEntry()) != null) {
                String name = e.getName().toLowerCase(Locale.ROOT);
                if (!name.endsWith("meta/meta.xml") && !name.equals("meta.xml")) continue;
                ByteArrayOutputStream out = new ByteArrayOutputStream();
                int n;
                while ((n = zip.read(buffer)) > 0) out.write(buffer, 0, n);
                String xml = out.toString(StandardCharsets.UTF_8.name());
                Matcher id = Pattern.compile("<title_id[^>]*>([0-9a-fA-F]{16})</title_id>").matcher(xml);
                if (!id.find()) return null;
                String titleId = id.group(1).toUpperCase(Locale.ROOT);
                String value = TITLES.get(titleId);
                if (value != null) {
                    int split = value.indexOf('\u0000');
                    return new Result(value.substring(0, split), titleId, value.substring(split + 1));
                }
                return new Result("Wii U Game", titleId, regionFromId(titleId));
            }
        } catch (IOException ignored) {
            return null;
        }
        return null;
    }

    private static boolean isZip(byte[] data) {
        return data.length >= 4 && data[0] == 'P' && data[1] == 'K';
    }

    private static String regionFromId(String id) {
        if (id.length() != 16) return "";
        switch (id.substring(14, 16)) {
            case "00": return "USA";
            case "01": return "EUR";
            default: return "";
        }
    }
}
