
import { db } from "../server/db";
import { tasks, contactTasks } from "@shared/schema";
import { count } from "drizzle-orm";

async function checkData() {
    try {
        const [tasksCount] = await db.select({ count: count() }).from(tasks);
        const [contactTasksCount] = await db.select({ count: count() }).from(contactTasks);

        console.log("Tasks count:", tasksCount.count);
        console.log("Contact Tasks count:", contactTasksCount.count);
    } catch (error) {
        console.error("Error checking data:", error);
    }
    process.exit(0);
}

checkData();
