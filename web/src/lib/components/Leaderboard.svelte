<script lang="ts">
import { dataState, NuiState, nuiState } from "$lib/utils";
import { scale, slide } from "svelte/transition";

interface User {
    name: string;
    nickname: string;
    imageUrl?: string;
    stats: { 
        earned: number; 
        drugsSold: number; 
        mostSellable: string;
    }
}

interface LeaderboardProps {
    player: User;
    users: User[];
    admin?: boolean;
}

let data: LeaderboardProps = $state($dataState as unknown as LeaderboardProps);
let settings: boolean = $state(false);
let shownUsers: string[] = $state([]);

let inputs: { nickname: string; imageUrl?: string } = $state({ nickname: data.player.nickname, imageUrl: data.player.imageUrl });
let filtered: User[] = $state([]);
let query: string = $state('');
let sort: 'earnings' | 'amount' = $state('earnings');
let direction: 'asc' | 'desc' = $state('desc');

$effect(() => {
    filtered = data.users
        .filter(user => user.nickname.toLowerCase().includes(query.toLowerCase()) || data.admin && user.name.toLowerCase().includes(query.toLowerCase()))
        .sort((a, b) => {
            if (sort === 'earnings')
                return direction === 'desc' ? b.stats.earned - a.stats.earned : a.stats.earned - b.stats.earned
            else if (sort === 'amount')
                return direction === 'desc' ? b.stats.drugsSold - a.stats.drugsSold : a.stats.drugsSold - b.stats.drugsSold
            else
                return 0
        })
})

function showSettings(changed?: boolean) {
    settings = !settings;

    if (changed) {
        // fetch nui
    }

    inputs = { nickname: data.player.nickname, imageUrl: data.player.imageUrl };
}
</script>

{#if $nuiState === NuiState.Leaderboard}
    <div class="leaderboard-container">
        <div class="leaderboard-wrapper p-5 pl-0 pr-0" style="pointer-events: {settings && 'none'};">
            <div class="flex items-center justify-between pr-5 pl-5">
                <div>
                    <p class="text-white text-2xl">Drug Dealers</p>
                    <p class="text-neutral-500 font-[Inter] text-sm">Take a look at dealers of this city</p>
                </div>
                <div class="text-white flex items-center gap-3">
                    <p class="text-lg">Welcome, <span class="font-bold text-lime-500 text-xl">{data.player.nickname}</span></p>
                    <div class="outline outline-2 rounded-full outline-offset-2 group cursor-pointer relative" onclick={() => showSettings()}>
                        <img src={data.player.imageUrl} onerror={(e: any) => { e.target.src = 'https://i.postimg.cc/nrJ96vNc/default-avatar-profile-icon-social-media-user-image-gray-avatar-icon-blank-profile-silhouette-vector.jpg' }} alt="user-profile"
                        class="rounded-full w-[50px] h-[50px] group-hover:opacity-50 transition-all">
                        <i class="hgi hgi-stroke hgi-edit-02 absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 text-white opacity-0 group-hover:opacity-100 transition-all
                        pointer-events-none"></i>
                    </div>
                </div>
            </div>
            <div class="mt-3 relative pr-5 pl-5">
                <input type="text" placeholder="Search..."
                class="bg-transparent placeholder:text-neutral-500 text-white font-[Inter] text-sm border border-neutral-700 rounded-md px-2 py-1 w-full
                focus:outline focus:outline-1 focus:outline-offset-1 focus:outline-neutral-300"
                bind:value={query}>
                <i class="hgi hgi-stroke hgi-search-01 text-neutral-500 absolute top-1/2 right-5 -translate-x-1/2 -translate-y-1/2 pointer-events-none"></i>
            </div>

            <div class="mx-5 mt-3 flex items-center justify-between">
                <div class="flex items-center gap-1">
                    <button onclick={() => sort = 'earnings'} class="flex items-center gap-2 rounded-full px-3 border duration-300 {sort === 'earnings' ? 'bg-lime-500/20 border-lime-500' : 'bg-white/5 border-neutral-600'}"><i class="hgi hgi-stroke hgi-dollar-circle"></i> Earnings</button>
                    <button onclick={() => sort = 'amount'} class="flex items-center gap-2 rounded-full px-3 border duration-300 {sort === 'amount' ? 'bg-lime-500/20 border-lime-500' : 'bg-white/5 border-neutral-600'}"><i class="hgi hgi-stroke hgi-package"></i> Amount</button>
                </div>

                <div class="flex items-center gap-1">
                    <button onclick={() => direction = 'desc'} class="flex items-center gap-2 rounded-full px-3 border duration-300 {direction === 'desc' ? 'bg-lime-500/20 border-lime-500' : 'bg-white/5 border-neutral-600'}"><i class="hgi hgi-stroke hgi-sort-by-down-02"></i> Descending</button>
                    <button onclick={() => direction = 'asc'} class="flex items-center gap-2 rounded-full px-3 border duration-300 {direction === 'asc' ? 'bg-lime-500/20 border-lime-500' : 'bg-white/5 border-neutral-600'}"><i class="hgi hgi-stroke hgi-sort-by-up-02"></i> Ascending</button>
                </div>
            </div>

            {#if filtered.length === 0}
                <div class="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 text-lg flex items-center gap-3">
                    <i class="hgi hgi-stroke hgi-user-question-02 text-3xl"></i>
                    <p class="font-[Inter]">No user found.</p>
                </div>
            {:else}
                <div class="h-[340px] mr-2.5 pt-3 pr-2.5 pl-5 grid grid-cols-3 place-content-start gap-2 overflow-auto">
                    {#each filtered as user, id}
                        <div class="bg-black/50 py-2 px-5 rounded-lg h-fit relative">
                            <div class="cursor-pointer" onclick={() => { if (shownUsers.includes(user.nickname)) shownUsers = shownUsers.filter(nickname => nickname !== user.nickname); else shownUsers.push(user.nickname) }}>
                                <p class="absolute -top-1 -left-1 bg-lime-500/50 rounded-full px-2">{id + 1}</p>
                                <div class="flex items-center justify-between">
                                    <div class="flex items-center gap-3">
                                        <img src={user.imageUrl} onerror={(e: any) => { e.target.src = 'https://i.postimg.cc/nrJ96vNc/default-avatar-profile-icon-social-media-user-image-gray-avatar-icon-blank-profile-silhouette-vector.jpg' }} alt="user-profile"
                                        class="rounded-full w-[50px] h-[50px] group-hover:opacity-50 transition-all">
                                        <div>
                                            <p class="text-lg">{user.nickname}</p>
                                            <p class="text-neutral-500">{data.admin && user.name}</p>
                                        </div>
                                    </div>
                                    <i class="fa-solid fa-chevron-down text-sm duration-300 {shownUsers.includes(user.nickname) && 'rotate-180'}"></i>
                                </div>
                            </div>
                            {#if shownUsers.includes(user.nickname)}
                                <div transition:slide class="font-[Inter] mt-2 flex flex-col gap-2">
                                    <p class="font-[Oswald] text-lg font-medium">User stats</p>
                                    <div class="text-sm">
                                        <p>Earnings</p>
                                        <p class="text-lime-500 font-medium">${user.stats.earned.toLocaleString('en-US')}</p>
                                    </div>
                                    <div class="text-sm">
                                        <p>Total drugs sold</p>
                                        <p class="text-lime-500 font-medium">{user.stats.drugsSold.toLocaleString('en-US')}</p>
                                    </div>
                                    <div class="text-sm">
                                        <p>Most sellable drugs</p>
                                        <p class="text-lime-500 font-medium">{user.stats.mostSellable}</p>
                                    </div>
                                </div>
                            {/if}
                        </div>
                    {/each}
                </div>
            {/if}

            {#if settings}
                <div class="leaderboard-settings" transition:scale>
                    <span></span>
                    <p class="text-xl">Change account settings</p>
                    <p class="text-neutral-500 text-sm font-[Inter]">Change your dealer's account settings</p>
                    <div class="my-3 flex items-center gap-3 w-full">
                        <div class="w-full flex flex-col gap-1">
                            <p class="text-[17px]">Change nickname</p>
                            <input type="text" class="bg-white/5 font-[Inter] text-[15px] w-full px-2 py-1 border border-neutral-700 rounded-md
                            focus:outline focus:outline-1 focus:outline-offset-1 focus:outline-neutral-300"
                            bind:value={inputs.nickname as unknown as string}>
                            <p class="text-sm font-[Inter] text-neutral-500">Your new nickname.</p>
                        </div>
                        <div class="w-full flex flex-col gap-1">
                            <p class="text-[17px]">Change profile picture</p>
                            <input type="text" class="bg-white/5 font-[Inter] text-[15px] w-full px-2 py-1 border border-neutral-700 rounded-md
                            focus:outline focus:outline-1 focus:outline-offset-1 focus:outline-neutral-300"
                            bind:value={inputs.imageUrl as unknown as string}>
                            <p class="text-sm font-[Inter] text-neutral-500">Your new profile picture.</p>
                        </div>
                    </div>
                    <div class="w-full flex items-center gap-3">
                        <button class="bg-red-700/20 border border-red-700 rounded-full w-full py-0.5 hover:bg-red-700/30 duration-300" onclick={() => showSettings()}>Cancel</button>
                        <button class="bg-lime-500/20 border border-lime-500 rounded-full w-full py-0.5 hover:bg-lime-500/30 duration-300" onclick={() => showSettings(true)}>Change</button>
                    </div>
                </div>
            {/if}
        </div>
    </div>
{/if}