<script lang="ts">
import { dataState, NuiState, nuiState } from "$lib/utils";
import { fetchNui } from "$lib/utils/fetchNui";
import { fade } from "svelte/transition";

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
}

interface ExtendedUser extends User {
    id: number;
}

interface LeaderboardProps {
    users: User[];
    admin?: boolean;
}

let data: LeaderboardProps = $state($dataState as unknown as LeaderboardProps);
let pageSize: number = 5;

let time: string = $state('08:42 AM');
let TAB: 'home' | 'profile' = $state('home');
let searchQuery: string = $state('');
let Users: ExtendedUser[] = $state([]);
let Player: User = data.users.find(user => user.myself) || data.users[0];
let SortType: 'ASC' | 'DESC' = $state('DESC');
let PAGE: number = $state(1);
let totalPages = $state(Math.max(1, Math.ceil(Users.length / pageSize)));

$effect(() => {
    const sorted = [...data.users].sort((a, b) => SortType === 'DESC' ? b.stats.earned - a.stats.earned : a.stats.earned - b.stats.earned);

    // Import id to user
    const ranked = sorted.map((user, id) => ({ ...user, id: id + 1 }));

    const filter = ranked.filter(user => 
        user.nickname.toLowerCase().includes(searchQuery.toLowerCase()) ||
        (data.admin && user.name.toLowerCase().includes(searchQuery.toLowerCase()))
    )

    totalPages = Math.max(1, Math.ceil(filter.length / pageSize));

    Users = filter.slice((PAGE - 1) * pageSize, PAGE * pageSize);
})

function getPlayerDrugs(user?: User) {
    const player = user || Player;
    const allDrugs = Object.values(player.drugs).filter(drug => drug.amount > 0);
    const sorted = allDrugs.sort((a, b) => b.amount - a.amount);

    // return first 3 drugs
    return sorted.slice(0, 3).map(drug => drug.label).join(', ')
}

</script>

{#if $nuiState === NuiState.Leaderboard}
    <div class="lb-container" transition:fade|global>
        <div class="lb-header">
            <div>
                <p>{time}</p>
                <i class="fa-solid fa-house"></i>
            </div>
            <div>
                <i class="fa-solid fa-user"></i>
            </div>
        </div>

        {#if TAB === 'home'}
            <div class="px-5 py-3 relative">
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
                                <td>Rank</td>
                                <td>User</td>
                                <td>Last active</td>
                                <td>Most sellable drugs</td>
                                <td>Earnings</td>
                            </tr>
                        </thead>
                        <tbody>
                            {#if Users.length < 1}
                                <tr class="empty">
                                    <td colspan="5" class="text-4xl">No users</td>
                                </tr>
                            {/if}

                            {#each Users as user}
                                <tr>
                                    <td>
                                        <p><span class="text-[10px] text-gray-400">#</span>{user.id}</p>
                                    </td>
                                    <td>
                                        <div class="flex items-center justify-center gap-3">
                                            <img src={user.imageUrl} class="w-[35px] h-[35px] rounded-full">
                                            <p>{user.nickname}</p>
                                        </div>
                                    </td>
                                    <td>{user.stats.lastActive}</td>
                                    <td>{getPlayerDrugs(user)}</td>
                                    <td>{Intl.NumberFormat('en-US', { style: "currency", currency: 'USD', maximumFractionDigits: 0 }).format(user.stats.earned)}</td>
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
    </div>
{/if}