<script lang="ts">
import { dataState } from "$lib/utils";
import { fetchNui } from "$lib/utils/fetchNui";
import { fade } from "svelte/transition";
import Loader from "./Loader.svelte";

interface User {
    identifier: string;
    name: string;
    nickname: string;
    imageUrl?: string;
    stats: { 
        earned: number;
        lastActive: string;
        reputation: number;
    },
    drugs: Record<string, { label: string, amount: number }>;
    myself?: boolean;
    online: boolean;
}

interface ExtendedUser extends User {
    id: number;
}

interface Challenge {
    title: string;
    description: string;
    progress: number;
    claimed: boolean;
}

interface LeaderboardProps {
    users: User[];
    admin?: boolean;
}

let mounting: boolean = true; // helper for first loading (won't load for the first time)
let data: LeaderboardProps = $state($dataState as unknown as LeaderboardProps);
let pageSize: number = 5;

let loading: boolean = $state(false);
let time: string = $state('08:42 AM');
let TAB: 'home' | 'profile' | 'challenges' = $state('home');
let searchQuery: string = $state('');
let Users: ExtendedUser[] = $state([]);
let Challenges: Challenge[] | undefined = $state();
let Player: ExtendedUser | undefined = $state();
let SortType: 'ASC' | 'DESC' = $state('DESC');
let SortBy: 'earned' | 'reputation' | 'totalDrugs' = $state('reputation');
let PAGE: number = $state(1);
let totalPages = $state(1);
let profile: ExtendedUser | undefined = $state();
let SettingType: 'imageUrl' | 'nickname' | undefined = $state();

$effect(() => {
    const sorted = [...data.users].sort((a, b) => {
        let aValue: number, bValue: number;

        switch (SortBy) {
            case 'reputation':
                aValue = a.stats.reputation;
                bValue = b.stats.reputation;

                break;
            case 'totalDrugs':
                aValue = Object.values(a.drugs).reduce((sum, drug) => sum + drug.amount, 0);
                bValue = Object.values(b.drugs).reduce((sum, drug) => sum + drug.amount, 0);

                break;
            default:
                aValue = a.stats.earned;
                bValue = b.stats.earned;
        }

        return SortType === 'DESC' ? bValue - aValue : aValue - bValue;
    });

    // Import id to user
    const ranked = sorted.map((user, id) => ({ ...user, id: id + 1 }));

    Player = ranked.find(user => user.myself) || ranked[0];

    const filter = ranked.filter(user => 
        user.nickname.toLowerCase().includes(searchQuery.toLowerCase()) ||
        (data.admin && user.name.toLowerCase().includes(searchQuery.toLowerCase()))
    )

    totalPages = Math.max(1, Math.ceil(filter.length / pageSize));

    Users = filter.slice((PAGE - 1) * pageSize, PAGE * pageSize);
})

// effect for loader
$effect(() => {
    TAB;

    if (mounting) {
        mounting = false;
        return
    };

    loading = true;

    const t = setTimeout(() => loading = false, 300);
    return () => clearTimeout(t);
})

function getPlayerDrugs(user: User, type?: 'all' | 'count') {
    const allDrugs = Object.values(user.drugs).filter(drug => drug.amount > 0);
    const sorted = allDrugs.sort((a, b) => b.amount - a.amount);

    if (sorted.length < 1)
        return 'No drugs sold'

    if (type === 'count')
        return sorted.reduce((sum, drug) => sum + drug.amount, 0)

    if (type === 'all')
        return sorted.map(drug => `${drug.amount}x ${drug.label}`).join(', ')

    // return first 3 drugs
    return sorted.slice(0, 3).map(drug => drug.label).join(', ')
}

function getStandingColor(standing: number): string {
    // first place
    if (standing === 1)
        return '#facc15'
    else if (standing === 2)
        return '#cbd5e1'
    else if (standing === 3)
        return '#dc2626'

    return '#ffffff'
}

function openProfile(user?: ExtendedUser) {
    const player = user || Player;

    profile = player as ExtendedUser;
    SettingType = undefined;
    TAB = 'profile';
}

async function editProfile() {
    const box = document.getElementById('setting-box') as HTMLElement;
    if (box === null || box.className === 'loader') return;

    const input = (document.getElementById('setting') as HTMLInputElement).value;
    if (!input || profile === undefined || SettingType === undefined || input === profile[SettingType]) return;

    box.className = 'loader';
    
    const response = await fetchNui('editProfile', { identifier: profile.identifier, type: SettingType, input: input })

    if (response) {
        // update users
        data.users = response;

        // update profile
        profile[SettingType] = input;
    }

    box.className = 'fa-solid fa-check';
}

async function openChallenges(user?: ExtendedUser) {
    const player = user || Player;

    profile = player as ExtendedUser;
    TAB = 'challenges';

    const response: Challenge[] = await fetchNui('getQuests', profile.identifier)
    Challenges = response;
}

async function handleChallenge(type: 'refresh' | 'claim', id: number) {
    const box = document.getElementById(`challenge-${id}-${type}`) as HTMLElement;
    
    if (box === null || box.className === 'loader' || profile === undefined) return;

    box.className = 'loader';

    const response: Challenge[] = await fetchNui(type + 'Quest', { identifier: profile.identifier, id: id })
    
    if (response) 
        Challenges = response

    box.className = `hgi hgi-stroke hgi-${type === 'refresh' ? 'reload' : 'hold-03 text-lg'} pointer-events-none`;
}

</script>

<div class="lb-background" transition:fade|global>
    <div class="lb-container">
        <div class="lb-header">
            <div>
                <p>{time}</p>
                <i class="fa-solid fa-house" onclick={() => TAB = 'home'}></i>
            </div>
            <div>
                <i class="fa-solid fa-briefcase" onclick={() => openChallenges()}></i>
                <i class="fa-solid fa-user" onclick={() => openProfile()}></i>
            </div>
        </div>

        {#if loading}
            <div class="w-full h-full flex items-center justify-center">
                <Loader />
            </div>
        {/if}

        {#if TAB === 'home' && !loading}
            <div class="px-5 py-3 relative" in:fade>
                <div class="flex items-center justify-between">
                    <div>
                        <p class="text-[30px] leading-7">Leaderboard</p>
                        <p class="text-gray-400">View the best sellers in this city</p>
                    </div>

                    <div class="relative">
                        <input type="text" placeholder="Search..." class="bg-neutral-900 rounded px-2 pr-8 py-1 text-sm font-[Inter] placeholder:text-neutral-500 w-[200px]
                        focus:outline focus:outline-1 focus:outline-offset-1 focus:outline-lime-500" bind:value={searchQuery}>
                        <i class="hgi hgi-stroke hgi-search-01 text-neutral-500 pointer-events-none absolute top-1/2 -translate-y-1/2 right-2"></i>
                    </div>
                </div>

                <div class="mt-3">
                    <table class="lb-table">
                        <thead>
                            <tr>
                                <td></td>
                                <td></td>
                                <td>Most sellable drugs</td>
                                <td>
                                    <div class="flex items-center gap-2 cursor-pointer" onclick={() => { SortBy = 'reputation'; SortType = SortType === 'DESC' ? 'ASC' : 'DESC'; }}>
                                        <p>REP</p>
                                        <i class="fa-solid {SortType === 'DESC' && SortBy === 'reputation' ? 'fa-arrow-down-wide-short' : 'fa-arrow-up-wide-short'} text-xs"></i>
                                    </div>
                                </td>
                                <td>
                                    <div class="flex items-center gap-2 cursor-pointer" onclick={() => { SortBy = 'totalDrugs'; SortType = SortType === 'DESC' ? 'ASC' : 'DESC'; }}>
                                        <p>Total drugs sold</p>
                                        <i class="fa-solid {SortType === 'DESC' && SortBy === 'totalDrugs' ? 'fa-arrow-down-wide-short' : 'fa-arrow-up-wide-short'} text-xs"></i>
                                    </div>
                                </td>
                            </tr>
                        </thead>
                        <tbody>
                            {#if Users.length < 1}
                                <tr class="empty">
                                    <td colspan="5" class="text-4xl">No users</td>
                                </tr>
                            {/if}

                            {#each Users as user}
                                <tr onclick={() => openProfile(user)}>
                                    <td>
                                        <p><span class="text-[10px] text-gray-400">#</span>{user.id}</p>
                                    </td>
                                    <td>
                                        <div class="flex items-center justify-center gap-3">
                                            <img src={user.imageUrl} class="w-[35px] h-[35px] rounded-full">
                                            <p>{user.nickname}</p>
                                        </div>
                                    </td>
                                    <td>{getPlayerDrugs(user)}</td>
                                    <td>{Number(user.stats.reputation.toFixed(2)).toString()}</td>
                                    <td>{getPlayerDrugs(user, 'count').toLocaleString('en-US')}</td>
                                </tr>
                            {/each}
                        </tbody>
                    </table>
                </div>

                <div class="lb-pagination">
                    <button onclick={() => PAGE--} disabled={PAGE <= 1} class="disabled:opacity-50">Previous</button>
                    <button onclick={() => PAGE++} disabled={PAGE >= totalPages} class="disabled:opacity-50">Next</button>
                </div>
            </div>
        {/if}

        {#if TAB === 'profile' && profile && !loading}
            <div class="px-5 py-3 relative" in:fade>
                <div class="flex items-center justify-between">
                    <div class="flex items-center gap-3 relative">
                        <div class="lb-profile-picture group" style="outline: solid {profile.online ? '#84cc16' : '#dc2626'} 1px; pointer-events: {(!data.admin && !profile.myself) && 'none'};"
                            onclick={() => SettingType = 'imageUrl'}>
                            <img src={profile.imageUrl} class="w-full h-full rounded-full group-hover:blur-sm duration-300">
                            <i class="fa-solid fa-pen text-xl absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 opacity-0 group-hover:opacity-100 duration-300"></i>
                        </div>
                        <div>
                            <div class="group relative w-fit" style="pointer-events: {(!data.admin && !profile.myself) && 'none'}; cursor: {(!data.admin && !profile.myself) ? 'none' : 'pointer'}"
                                onclick={() => SettingType = 'nickname'}>
                                <p class="text-[25px] leading-relaxed">{profile.nickname}</p>
                                <i class="fa-solid fa-pen absolute -top-1 -right-5 opacity-0 group-hover:opacity-100 duration-300"></i>
                            </div>
                            <p class="text-[16px] text-gray-400 font-light leading-4">Last active {profile.stats.lastActive}</p>
                            <p class="text-[16px] text-gray-400 font-light">Dealer's reputation {Number(profile.stats.reputation.toFixed(2)).toString()} rep</p>
                            {#if profile.myself || data.admin}
                                <button class="bg-neutral-900 text-sm font-light px-5 py-0.5 rounded-full border border-neutral-700 mt-1 hover:bg-neutral-800 duration-300"
                                    onclick={() => openChallenges(profile)}>Daily Challenges</button>
                            {/if}
                        </div>
                        <div class="lb-profile-position">
                            <span class="text-gray-400 text-lg">#</span>
                            <p class="text-3xl" style="color: {getStandingColor(profile.id)}; filter: drop-shadow(0 0 5px {getStandingColor(profile.id)});">{profile.id}</p>
                        </div>
                    </div>

                    {#if SettingType}
                        <div class="flex items-center gap-2" in:fade>
                            <input id="setting" type="text" placeholder={`New ${SettingType === 'imageUrl' ? 'profile picture' : 'nickname'}`} defaultValue={profile[SettingType]}
                            class="bg-neutral-900 rounded px-2 py-1 text-sm font-[Inter] placeholder:text-neutral-500 w-[200px]
                                focus:outline focus:outline-1 focus:outline-offset-1 focus:outline-lime-500">
                            <div class="border border-lime-500 w-7 h-7 rounded-full flex items-center justify-center cursor-pointer bg-lime-500/10 hover:bg-lime-500/25 duration-300">
                                <div id="setting-box" class="fa-solid fa-check"
                                    onclick={() => editProfile()}></div>
                            </div> 
                        </div>
                    {/if}
                </div>

                <div class="mt-3">
                    <p class="text-xl">Player's statistics</p>
                    <div>
                        <table class="lb-table">
                            <thead>
                                <tr>
                                    <td>Reputation</td>
                                    <td>Last active</td>
                                    {#if data.admin || profile.myself}<td>Character name</td>{/if}
                                    <td>Sold drugs</td>
                                    {#if data.admin || profile.myself}<td>Earnings</td>{/if}
                                </tr>
                            </thead>
                            <tbody>
                                <tr class="empty">
                                    <td>{Number(profile.stats.reputation.toFixed(2)).toString()}</td>
                                    <td>{profile.stats.lastActive}</td>
                                    {#if data.admin || profile.myself}<td>{profile.name}</td>{/if}
                                    <td>{getPlayerDrugs(profile, 'all')}</td>
                                    {#if data.admin || profile.myself}
                                        <td>{Intl.NumberFormat('en-US', { style: "currency", currency: 'USD', maximumFractionDigits: 0 }).format(profile.stats.earned)}</td>
                                    {/if}
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        {/if}

        {#key Challenges}
            {#if TAB === 'challenges' && profile && Challenges && !loading}
                <div class="px-5 py-3 relative" in:fade>
                    <div>
                        <p class="text-[30px] leading-9">Daily challenges</p>
                        <p class="text-gray-400">Check {profile.nickname}'s daily challenges</p>
                    </div>

                    <div class="flex flex-col gap-1 mt-3 h-[290px] overflow-auto -mr-2.5 pr-2.5">
                        {#each Challenges as challenge, id}
                            <div class="bg-gradient-to-r from-[#0a0a0aa0] to-[#17171750] p-5 rounded flex items-center justify-between">
                                <div>
                                    <p class="text-lg">{challenge.title}</p>
                                    <p class="text-gray-400 font-light">{challenge.description}</p>
                                </div>
                                <div class="flex items-center gap-3">
                                    <div class="w-[175px] h-[5px] bg-neutral-950">
                                        <div class="h-full bg-lime-500" style="width: {challenge.progress}%; filter: drop-shadow(0 0 5px #84cc16);"></div>
                                    </div>
                                    {#if challenge.claimed}
                                        <div class="border border-lime-500 w-7 h-7 rounded-full flex items-center justify-center cursor-pointer bg-lime-500/10 pointer-events-none">
                                            <div class="fa-solid fa-check"></div>
                                        </div> 
                                    {:else}
                                        {#if challenge.progress < 100}
                                            <div class="border border-lime-500 w-8 h-8 rounded-full flex items-center justify-center cursor-pointer bg-lime-500/10 hover:bg-lime-500/25 duration-300"
                                                onclick={() => handleChallenge('refresh', id)}>
                                                <div id="challenge-{id}-refresh" class="hgi hgi-stroke hgi-reload pointer-events-none"></div>
                                            </div>
                                        {/if}
                                        <div class="border border-lime-500 w-8 h-8 rounded-full flex items-center justify-center cursor-pointer bg-lime-500/10 hover:bg-lime-500/25 duration-300"
                                             onclick={() => handleChallenge('claim', id)}>
                                            <div id="challenge-{id}-claim" class="hgi hgi-stroke hgi-hold-03 text-lg pointer-events-none"></div>
                                        </div>
                                    {/if}
                                </div>
                            </div>
                        {/each}
                    </div>
                </div>
            {/if}
        {/key}
    </div>
</div>