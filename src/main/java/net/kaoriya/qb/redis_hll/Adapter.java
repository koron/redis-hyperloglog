package net.kaoriya.qb.redis_hll;

import java.nio.charset.Charset;
import java.util.Arrays;

import redis.clients.jedis.Jedis;

public class Adapter
{
    public final static int DEFAULT_BITS = 9;
    public final static String SHA1_ADD =
        "2eb7a83ccc6847dec2eeaaa46203b1564a9ae73e";
    public final static String SHA1_COUNT =
        "c69a161cc39eb38a6483b9fab82f00565b482064";

    private int defaultBits;
    private Charset charset;
    private Jedis jedis;

    public Adapter(Jedis jedis, int defaultBits)
    {
        this.defaultBits = defaultBits;
        this.charset = Charset.forName("UTF-8");
        this.jedis = jedis;
    }

    public Adapter(Jedis jedis)
    {
        this(jedis, DEFAULT_BITS);
    }

    public final void add(String name, String str)
    {
        add(this.defaultBits, name, str);
    }

    public final void add(String name, byte[] buffer)
    {
        add(this.defaultBits, name, buffer);
    }

    public final void add(String name, long value)
    {
        add(this.defaultBits, name, value);
    }

    public final long count(String... names)
    {
        return count(this.defaultBits, names);
    }

    public final void add(int bits, String name, String str)
    {
        add(bits, name, calcHash(str));
    }

    public final void add(int bits, String name, byte[] buffer)
    {
        add(bits, name, calcHash(buffer));
    }

    public final void add(int bits, String name, long value)
    {
        String[] args = {
            name,
            Integer.toString(bits),
            Long.toString(value)
        };
        this.jedis.evalsha(getAddSHA1(), 1, args);
    }

    public final long count(int bits, String... names)
    {
        String[] args = new String[names.length + 1];
        for (int i = 0, len = names.length; i < len; ++i) {
            args[i] = names[i];
        }
        args[names.length] = Integer.toString(bits);
        Long retval = (Long)this.jedis.evalsha(getCountSHA1(), names.length,
                args);
        return retval != null ? retval.longValue() : -1;
    }

    protected long calcHash(String str)
    {
        return calcHash(str.getBytes(this.charset));
    }

    protected long calcHash(byte[] buffer)
    {
        int value = MurmurHash3.murmurhash3_x86_32(buffer, 0, buffer.length,
                0);
        return value >= 0 ? (long)value : (long)(4294967296L + value);
    }

    private String getAddSHA1()
    {
        // FIXME: make more flexible.
        return SHA1_ADD;
    }

    private String getCountSHA1()
    {
        // FIXME: make more flexible.
        return SHA1_COUNT;
    }
}
