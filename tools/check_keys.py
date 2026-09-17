#!/usr/bin/env python3
"""Refuse a build that would orphan anyone's ticks.

Every job on the trade lists is keyed by rowKey(room, action). A tick or a
note lives against that key in the database, so a build that drops or
rewords a row leaves the tick with nothing to attach to. This loads the
build that is live and the build about to go out, each once per tower,
with the Supabase client mocked so nothing is written anywhere, gathers
the keys from the page, and fails if any key on the live build is missing
from the new one.

    python tools/check_keys.py live.html new.html

Exit 0 when every key survives, 1 when one would be lost, 2 on a page
error. Needs playwright (pip install playwright && playwright install chromium).
"""
import asyncio
import os
import sys

from playwright.async_api import async_playwright

HERE = os.path.dirname(os.path.abspath(__file__))
MOCK = open(os.path.join(HERE, "mock_supabase.js"), encoding="utf-8").read()
TOWERS = (1, 2, 3, 4)


async def keys_for(browser, path, tower):
    ctx = await browser.new_context()
    await ctx.route("**/cdn.jsdelivr.net/**", lambda r: asyncio.ensure_future(r.abort()))
    await ctx.route("**/unpkg.com/**", lambda r: asyncio.ensure_future(r.abort()))
    await ctx.add_init_script(MOCK)
    page = await ctx.new_page()
    errors = []
    page.on("pageerror", lambda e: errors.append(str(e)))
    await page.goto("file://" + os.path.abspath(path) + "?tower=%d" % tower)
    await page.wait_for_timeout(1200)
    keys = await page.eval_on_selector_all(
        "#sections input[type=checkbox][data-id]",
        "els => els.map(e => e.getAttribute('data-id'))")
    await ctx.close()
    return set(keys), errors


async def main(live, new):
    async with async_playwright() as p:
        exe = os.environ.get("CHROME_PATH")
        browser = await p.chromium.launch(executable_path=exe) if exe else await p.chromium.launch()
        old_keys, new_keys = set(), set()
        for tower in TOWERS:
            k, errs = await keys_for(browser, live, tower)
            old_keys |= k
            k2, errs2 = await keys_for(browser, new, tower)
            new_keys |= k2
            if errs2:
                print("page errors on the new build, tower %d: %s" % (tower, errs2))
                await browser.close()
                return 2
            print("tower %d: live %d jobs, new %d jobs" % (tower, len(k), len(k2)))
        await browser.close()
    lost = sorted(old_keys - new_keys)
    print("live build: %d keys; new build: %d keys; lost: %d" % (len(old_keys), len(new_keys), len(lost)))
    if lost:
        print("These jobs are on the live build but not the new one, so their ticks")
        print("and notes would be orphaned. Reword nothing that is ticked; add, do")
        print("not replace. Keys lost:")
        for k in lost[:50]:
            print("  " + k)
        return 1
    print("KEYS-OK: every job on the live build is on the new one.")
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(2)
    sys.exit(asyncio.run(main(sys.argv[1], sys.argv[2])))
