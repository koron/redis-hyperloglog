package net.kaoriya.qb.redis_hll;

import redis.clients.jedis.Jedis;
import redis.clients.jedis.JedisPool;
import redis.clients.jedis.JedisPoolConfig;

public final class Main
{
    public static void main(String[] args)
    {
        String host = args.length >= 1 ? args[0] : "127.0.0.1";
        JedisPool pool = new JedisPool(new JedisPoolConfig(), host);
        Jedis jedis = pool.getResource();
        try {
            run(jedis);
        } finally {
            pool.returnResource(jedis);
        }
        pool.destroy();
    }

    public static void run(Jedis jedis)
    {
        Adapter adapter = new Adapter(jedis, 4);

        // Setup 4 counters: set1, set2, set3, set4
        for (int i = 1; i <= 50; ++i) {
            adapter.add("set1", "item" + i);
        }
        for (int i = 51; i <= 100; ++i) {
            adapter.add("set2", "item" + i);
        }
        for (int i = 1; i <= 100; i += 2) {
            adapter.add("set3", "item" + i);
        }
        for (int i = 2; i <= 100; i += 2) {
            adapter.add("set4", "item" + i);
        }

        System.out.println(adapter.count("set1"));
        System.out.println(adapter.count("set2"));
        System.out.println(adapter.count("set3"));
        System.out.println(adapter.count("set4"));
        System.out.println(adapter.count("set1", "set2"));
        System.out.println(adapter.count("set3", "set4"));
        System.out.println(adapter.count("set1", "set3"));
        System.out.println(adapter.count("set1", "set4"));
        System.out.println(adapter.count("set2", "set3"));
        System.out.println(adapter.count("set2", "set4"));
    }
}
